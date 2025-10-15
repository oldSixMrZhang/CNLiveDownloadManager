//
//  CNLiveDownloadManager.m
//  CNLiveDownloadManager
//
//  Created by 殷巧娟 on 2019/6/1.
//

#import "CNLiveAudioDownloadManager.h"
#import "NSString+CNLiveExtension.h"
#import "CNLiveAlbumAudioListModel.h"
#import "NSURLSession+CNLiveCorrectedResumeData.h"
#import "CNLiveVodUrlUtil.h"
#import "NSString+CNLiveExtension.h"
#import "CNLiveNetworking.h"
#import "CNUserInfoManager.h"
#import "CNLiveDataBaseManager.h"
#import "CNLiveDefinesHeader.h"
#import "QMUIKit.h"
#import "CNLiveTimeTools.h"
#import "CNLiveDownload.h"
#define CNLiveAppKeyWindow [UIApplication sharedApplication].delegate.window
;@interface CNLiveAudioDownloadManager ()<NSURLSessionDelegate,NSURLSessionDownloadDelegate,UIAlertViewDelegate>
@property (nonatomic, strong) NSURLSession *session;                 // NSURLSession
@property (nonatomic, strong) NSMutableDictionary *dataTaskDic;      // 同时下载多个文件，需要创建多个NSURLSessionDownloadTask，用该字典来存储
@property (nonatomic, strong) NSMutableDictionary *downloadTaskDic;  // 记录任务调用startDownloadTask:方法时间，禁止同一任务极短时间重复调用，防止状态显示错误
@property (nonatomic, assign) NSInteger currentCount;                // 当前正在下载的个数
@property (nonatomic, assign) NSInteger maxConcurrentCount;          // 最大同时下载数量
@property (nonatomic, assign) BOOL isNohaveNet; //没网
@end

@implementation CNLiveAudioDownloadManager
+ (instancetype)shareManager {
    static CNLiveAudioDownloadManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    
    return manager;
}
- (instancetype)init
{
    if (self = [super init]) {
        // 初始化
        _currentCount = 0;
        _maxConcurrentCount = 1;
        _allowsCellularAccess = NO;
        _dataTaskDic = [NSMutableDictionary dictionary];
        _downloadTaskDic = [NSMutableDictionary dictionary];
        // 单线程代理队列
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;
        // 后台下载标识
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"CNDownloadBackgroundSessionIdentifier"];
        // 允许蜂窝网络下载，默认为YES，这里开启，我们添加了一个变量去控制用户切换选择
        configuration.allowsCellularAccess = YES;
        // 创建NSURLSession，配置信息、代理、代理线程
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:queue];
        [self monitorTheNetwork];
        [self startDownloadWaitingTask];
    }
    
    return self;
}
#pragma mark -请求下载Url
- (void)getDownloadUrl:(CNLiveAlbumAudioListModel *)model {
    self.isloading = YES;
    [[CNLiveVodUrlUtil manager] getVodUrlWithVid:model.activityId channelName:model.channelName sid:CNUserShareModelUid playType:@"a" tag:@"" completeBlock:^(NSString * _Nonnull vodUrl) {
        if (vodUrl) {
            model.url = vodUrl;
            self.isloading = NO;
            [self startDownloadTask:model];
        }else {
            CNLiveAlbumAudioListModel *downloadModel = [[CNLiveDataBaseManager shareManager] getModelwithActivityId:model.activityId];
            if (!downloadModel) {
                [QMUITips showWithText:@"添加下载失败" inView:CNLiveAppKeyWindow hideAfterDelay:1.5f];
            }else {
                downloadModel.state = CNDownloadStateError;
                [[CNLiveDataBaseManager shareManager] updateWithModel:downloadModel option:CNDBUpdateOptionState | CNDBUpdateOptionLastStateTime];
            }
            //请求失败,继续下载下一个等待的数据
            self.isloading = NO;
            [self startDownloadWaitingTask];
        }
    }];
}
#pragma mark -加入准备下载任务
- (void)startDownloadTask:(CNLiveAlbumAudioListModel *)model
{
      __weak typeof(self) weakSelf = self;
    // 同一任务，1.0s内禁止重复调用
    if ([[NSDate date] timeIntervalSinceDate:[weakSelf.downloadTaskDic valueForKey:model.activityId]] < 1.0f) return;
    if (!CNLiveStringIsEmpty(model.activityId)) {
        [weakSelf.downloadTaskDic setValue:[NSDate date] forKey:model.activityId];
    }
    // 取出数据库中模型数据，如果不存在，添加到数据库中（注意：需要保证url唯一，若多条目同一url，则要另做处理）
    CNLiveAlbumAudioListModel *downloadModel = [[CNLiveDataBaseManager shareManager] getModelwithActivityId:model.activityId];
    if (!downloadModel) {
        downloadModel = model;
        [[CNLiveDataBaseManager shareManager] insertModel:downloadModel];
    }
    // 更新状态为等待下载
    downloadModel.url = model.url;
    downloadModel.state = CNDownloadStateWaiting;
    [[CNLiveDataBaseManager shareManager] updateWithModel:downloadModel option:CNDBUpdateOptionState | CNDBUpdateOptionLastStateTime];
    
    // 下载（给定一个等待时间，保证currentCount更新）
    [NSThread sleepForTimeInterval:0.1f];
    if ((weakSelf.currentCount < weakSelf.maxConcurrentCount) && [weakSelf networkingAllowsDownloadTask])
    {
        [weakSelf downloadwithModel:downloadModel];
    }
}
#pragma mark -开始真正下载
- (void)downloadwithModel:(CNLiveAlbumAudioListModel *)model
{
    _currentCount++;
    // cancelByProducingResumeData:回调有延时，给定一个等待时间，重新获取模型，保证获取到resumeData
    [NSThread sleepForTimeInterval:0.3f];
    CNLiveAlbumAudioListModel *downloadModel = [[CNLiveDataBaseManager shareManager] getModelwithActivityId:model.activityId];
    
    // 更新状态为开始
    downloadModel.state = CNDownloadStateDownloading;
    [[CNLiveDataBaseManager shareManager] updateWithModel:downloadModel option:CNDBUpdateOptionState];
    
    // 创建NSURLSessionDownloadTask
    NSURLSessionDownloadTask *downloadTask;
    
    if (downloadModel.resumeData) {
        CGFloat version = [[[UIDevice currentDevice] systemVersion] floatValue];
        if (version >= 10.0 && version < 10.2) {
            downloadTask = [_session downloadTaskWithCorrectResumeData:downloadModel.resumeData];
        }else {
            downloadTask = [_session downloadTaskWithResumeData:downloadModel.resumeData];
        }
        
    }else {
        downloadTask = [_session downloadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:downloadModel.url]]];
    }
    // 添加描述标签
    downloadTask.taskDescription = downloadModel.url;
    
    // 更新存储的NSURLSessionDownloadTask对象
    if (!CNLiveStringIsEmpty(downloadModel.activityId)) {
        [_dataTaskDic setValue:downloadTask forKey:downloadModel.activityId];
    }
    // 启动（继续下载）
    [downloadTask resume];
}
#pragma mark -全部暂停和没网的时候暂停下载中和等待的数据
- (void)pauseAllDownloadTask:(BOOL)isNoHaveNet{
     __weak typeof(self) weakSelf = self;
    NSArray<CNLiveAlbumAudioListModel*> *downloadTasks = [[CNLiveDataBaseManager shareManager] getAllUnDownloadedData];
    NSInteger count = downloadTasks.count;
    for(NSInteger i=0; i<count; i++){
        CNLiveAlbumAudioListModel *model = downloadTasks[i];
        // 取最新数据
        CNLiveAlbumAudioListModel*downloadModel = [[CNLiveDataBaseManager shareManager] getModelwithActivityId:model.activityId];
        if(downloadModel.state == CNDownloadStateDownloading){
            // 获取NSURLSessionDownloadTask
            NSURLSessionDownloadTask *downloadTask = [_dataTaskDic valueForKey:model.activityId];
            [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                // 更新下载数据
                model.resumeData = resumeData;
                [[CNLiveDataBaseManager shareManager] updateWithModel:model option:CNDBUpdateOptionResumeData];
                // 更新当前正在下载的个数
                self.isloading = NO;
                if (weakSelf.currentCount > 0) weakSelf.currentCount--;
            }];
            if (!isNoHaveNet) {
                downloadModel.state = CNDownloadStatePaused;
            }else {
                downloadModel.state = CNDownloadStatePausedNoNetwork;
            }
        }else if (downloadModel.state == CNDownloadStateWaiting){
            if (!isNoHaveNet) {
                downloadModel.state = CNDownloadStatePaused;
            }else{
                downloadModel.state = CNDownloadStatePausedNoNetwork;
            }
        }
        // 更新数据库状态为暂停
        [[CNLiveDataBaseManager shareManager] updateWithModel:downloadModel option:CNDBUpdateOptionState];
    }
}

#pragma mark -全部开始和无网的开始因无网暂停的下载
- (void)startAllDownloadTask:(BOOL)isHaveNoNet{
    NSArray<CNLiveAlbumAudioListModel *> *downloadTasks = [[CNLiveDataBaseManager shareManager] getAllUnDownloadedData];
    NSInteger count = downloadTasks.count;
    for(NSInteger i=0; i<count; i++){
        CNLiveAlbumAudioListModel *model = downloadTasks[i];
        // 取最新数据
        CNLiveAlbumAudioListModel *downloadModel = [[CNLiveDataBaseManager shareManager] getModelwithActivityId:model.activityId];
        //暂停，默认，错误
        if (!isHaveNoNet) {
            if(downloadModel.state == CNDownloadStatePaused || downloadModel.state == CNDownloadStatePausedNoNetwork ||downloadModel.state == CNDownloadStateDefault || downloadModel.state == CNDownloadStateError){
                downloadModel.state = CNDownloadStateWaiting;
                [[CNLiveDataBaseManager shareManager] updateWithModel:downloadModel option:CNDBUpdateOptionState | CNDBUpdateOptionLastStateTime];
            }
        }else {
            if(downloadModel.state == CNDownloadStatePausedNoNetwork || downloadModel.state == CNDownloadStateDefault || downloadModel.state == CNDownloadStateError ){
                downloadModel.state = CNDownloadStateWaiting;
                [[CNLiveDataBaseManager shareManager] updateWithModel:downloadModel option:CNDBUpdateOptionState | CNDBUpdateOptionLastStateTime];
            }
        }
    }
    [self startDownloadWaitingTask];
    //获取等待下载的数据,开始下载
}
#pragma mark -单条暂停
- (void)pauseDownloadTask:(CNLiveAlbumAudioListModel *)model
{
    // 取最新数据
    CNLiveAlbumAudioListModel *downloadModel = [[CNLiveDataBaseManager shareManager] getModelwithActivityId:model.activityId];
    
    // 取消任务
    [self cancelTaskWithModel:downloadModel delete:NO];
    
    // 更新数据库状态为暂停
    downloadModel.state = CNDownloadStatePaused;
    [[CNLiveDataBaseManager shareManager] updateWithModel:downloadModel option:CNDBUpdateOptionState];
}
#pragma mark 删除下载任务及本地缓存
- (void)deleteTaskAndCache:(CNLiveAlbumAudioListModel *)model
{
    // 如果正在下载，取消任务
    [self cancelTaskWithModel:model delete:YES];
    
    // 删除本地缓存、数据库数据
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (!CNLiveStringIsEmpty(model.localPath)) {
            [[NSFileManager defaultManager] removeItemAtPath:model.localPath error:nil];
            [[CNLiveDataBaseManager shareManager] deleteModelWithUrl:model.activityId];
        }else {
            [[CNLiveDataBaseManager shareManager] deleteModelWithUrl:model.activityId];
        }
    });
}

#pragma mark -取消任务
- (void)cancelTaskWithModel:(CNLiveAlbumAudioListModel *)model delete:(BOOL)delete
{
     __weak typeof(self) weakSelf = self;
    if (model.state == CNDownloadStateDownloading) {
        // 获取NSURLSessionDownloadTask
        NSURLSessionDownloadTask *downloadTask = [_dataTaskDic valueForKey:model.activityId];
        
        // 取消任务
        [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            // 更新下载数据
            model.resumeData = resumeData;
            [[CNLiveDataBaseManager shareManager] updateWithModel:model option:CNDBUpdateOptionResumeData];
            // 更新当前正在下载的个数
            if (weakSelf.currentCount > 0) weakSelf.currentCount--;
            
            // 开启等待下载任务
            [weakSelf startDownloadWaitingTask];
        }];
        
        // 移除字典存储的对象
        if (delete) {
            if (!CNLiveStringIsEmpty(model.activityId)) {
                [_dataTaskDic removeObjectForKey:model.activityId];
                [_downloadTaskDic removeObjectForKey:model.activityId];
            }
        }
    }
}

#pragma mark - 开始下载等待任务
- (void)startDownloadWaitingTask
{
    self.isloading = NO;
    if ((_currentCount < _maxConcurrentCount) && [self networkingAllowsDownloadTask]) {
        // 获取下一条等待的数据
        NSArray *array = [[CNLiveDataBaseManager shareManager] getAllWaitingData];
        if (array.count > 0 && !self.isloading) {
            [self getDownloadUrl:array[0]];
        }
    }
}

#pragma mark - NSURLSessionDownloadDelegate
#pragma mark - 接收到服务器返回数据，会被调用多次
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    // 获取模型
    CNLiveAlbumAudioListModel *model = [[CNLiveDataBaseManager shareManager] getModelWithUrl:downloadTask.taskDescription];
    
    // 更新当前下载大小
    model.tmpFileSize = (NSUInteger)totalBytesWritten;
    model.totalFileSize = (NSUInteger)totalBytesExpectedToWrite;
    
    // 计算速度时间内下载文件的大小
    model.intervalFileSize += (NSUInteger)bytesWritten;
    
    // 获取上次计算时间与当前时间间隔
    NSInteger intervals = [CNLiveTimeTools getIntervalsWithTimeStamp:model.lastSpeedTime];
    if (intervals >= 1) {
        // 计算速度
        model.speed = model.intervalFileSize / intervals;
        
        // 重置变量
        model.intervalFileSize = 0;
        model.lastSpeedTime = [CNLiveTimeTools getTimeStampWithDate:[NSDate date]];
    }
    
    // 计算进度
    model.progress = 1.0 * model.tmpFileSize / model.totalFileSize;
    
    // 更新数据库中数据
    [[CNLiveDataBaseManager shareManager] updateWithModel:model option:CNDBUpdateOptionProgressData];
    
    // 进度通知
    [[NSNotificationCenter defaultCenter] postNotificationName:WjjAudioDownloadProgressNotification object:model];
}

#pragma mark - 下载完成
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    // 获取模型
    CNLiveAlbumAudioListModel *model = [[CNLiveDataBaseManager shareManager] getModelWithUrl:downloadTask.taskDescription];
    
    // 移动文件，原路径文件由系统自动删除
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path =  [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"albumAudioList_%@",model.albumId]];
    if (![fileManager fileExistsAtPath:path]) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if (!CNLiveStringIsEmpty(model.localPath)) {
        [fileManager moveItemAtPath:[location path] toPath:model.localPath error:&error];
    }
    if (error) NSLog(@"下载完成，移动文件发生错误：%@ ---- %@", error,model.localPath);
}

#pragma mark - NSURLSessionTaskDelegate
#pragma mark -请求完成
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    // 调用cancel方法直接返回，在相应操作是直接进行处理
    if (error && [error.localizedDescription isEqualToString:@"cancelled"]) return;
    
    // 获取模型
    CNLiveAlbumAudioListModel *model = [[CNLiveDataBaseManager shareManager] getModelWithUrl:task.taskDescription];
    
    // 下载时进程杀死，重新启动时回调错误
    if (error && [error.userInfo objectForKey:NSURLErrorBackgroundTaskCancelledReasonKey]) {
        model.state = CNDownloadStateWaiting;
        model.resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
        [[CNLiveDataBaseManager shareManager] updateWithModel:model option:CNDBUpdateOptionState | CNDBUpdateOptionResumeData];
        return;
    }
    // 更新下载数据、任务状态
    if (error) {
        model.state = CNDownloadStateError;
        model.resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
        [[CNLiveDataBaseManager shareManager] updateWithModel:model option:CNDBUpdateOptionResumeData];
        
    }else {
        model.state = CNDownloadStateFinish;
    }
    
    // 更新数据
    if (_currentCount > 0) _currentCount--;
    if (!CNLiveStringIsEmpty(model.activityId)) {
        [_dataTaskDic removeObjectForKey:model.activityId];
        [_downloadTaskDic removeObjectForKey:model.activityId];
    }
    // 更新数据库状态
    [[CNLiveDataBaseManager shareManager] updateWithModel:model option:CNDBUpdateOptionState];
    
    // 开启等待下载任务
    [self startDownloadWaitingTask];
    NSLog(@"\n    文件：%@，didCompleteWithError\n    本地路径：%@ \n    错误：%@ \n", model.title, model.localPath, error);
}

#pragma mark - NSURLSessionDelegate
// 应用处于后台，所有下载任务完成及NSURLSession协议调用之后调用
//这个放在主工程delegate里实现
//- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
//{
//
//    dispatch_async(dispatch_get_main_queue(), ^{
//        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//        if (appDelegate.backgroundSessionCompletionHandler) {
//            void (^completionHandler)(void) = appDelegate.backgroundSessionCompletionHandler;
//            appDelegate.backgroundSessionCompletionHandler = nil;
//            // 执行block，系统后台生成快照，释放阻止应用挂起的断言
//            completionHandler();
//        }
//    });
//}

// 判断是否有网络和是否同意了4G
- (BOOL)networkingAllowsDownloadTask
{
    // 当前网络状态
    // 无网络 或 （当前为蜂窝网络，且不允许蜂窝网络下载）
    if (![CNLiveNetworking isNetworking]&& !_allowsCellularAccess) {
        return NO;
    }
    return YES;
    
}
#pragma mark -添加网络通知
- (void)monitorTheNetwork {
     __weak typeof(self) weakSelf = self;
    [CNLiveAudioDownloadManager networkStatusWithBlock:^(CNLiveNetworkStatusType status) {
        switch (status) {
            case CNLiveNetworkStatusNotReachable:{
                NSLog(@"无网");
                if ([[CNLiveDataBaseManager shareManager] getLastDownloadingModel]) {
                    [weakSelf pauseAllDownloadTask:YES];
                    weakSelf.isNohaveNet = YES; //还要考虑4G切换到wifi和wifi切换到4G
                }
            }
                break;
            case CNLiveNetworkStatusUnknown:{
                NSLog(@"未知网络");
                if ([[CNLiveDataBaseManager shareManager] getLastDownloadingModel]) {
                    [weakSelf pauseAllDownloadTask:YES];
                    weakSelf.isNohaveNet = YES;
                }
            }
                break;
            case CNLiveNetworkStatusReachableViaWiFi:{
                NSLog(@"wifi");
                if(weakSelf.isNohaveNet) {
                    [weakSelf startAllDownloadTask:YES];
                }
            }
                break;
            case CNLiveNetworkStatusReachableViaWWAN:{
                NSLog(@"4G");
                if (weakSelf.isNohaveNet && weakSelf.allowsCellularAccess ) {
                    [weakSelf startAllDownloadTask:YES];
                }else {
                    if ([[CNLiveDataBaseManager shareManager] getLastDownloadingModel]) {
                        [weakSelf pauseAllDownloadTask:YES];
                        weakSelf.isNohaveNet = YES; //还要考虑4G切换到wifi和wifi切换到4G
                        [weakSelf showAlertView];
                    }
                }
            }
                break;
            default:
                break;
        }
    }];
}
#pragma mark -IM连接成功通知
//- (void)IMConnectSucc {
//    [self addDownloadReachabilityManager];
//}
#pragma mark -网络弹框
- (void)showAlertView {
    
    UIAlertView *alertView=[[UIAlertView alloc]initWithTitle:@"当前无Wifi,是否允许用流量继续下载" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"继续下载", nil];
    [alertView show];
}

//监听点击事件 代理方法
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex==0) {
        NSLog(@"你点击了取消");
    }
    else if (buttonIndex==1) {
        _allowsCellularAccess = YES;
        [self startAllDownloadTask:YES];
    }
}

- (void)dealloc
{
    [CNLiveAudioDownloadManager removeNetworkStatue];
    [_session invalidateAndCancel];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

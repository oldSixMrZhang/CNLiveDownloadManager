//
//  CNLiveDataBaseManager.m
//  CNLiveDownloadManager
//
//  Created by 殷巧娟 on 2019/6/1.
//

#import "CNLiveDataBaseManager.h"
#import "CNLiveTimeTools.h"
#import "CNLiveAudioDownloadManager.h"
#import "CNLiveAlbumAudioListModel.h"
#import "CNLiveTimeTools.h"
#import "CNLiveDownload.h"
typedef NS_ENUM(NSInteger, CNDBGetDateOption) {
    CNDBGetDateOptionAllCacheData = 0,      // 所有缓存数据
    CNDBGetDateOptionAllDownloadingData,    // 所有正在下载的数据
    CNDBGetDateOptionAllDownloadedData,     // 所有下载完成的数据
    CNDBGetDateOptionAllUnDownloadedData,   // 所有未下载完成的数据
    CNDBGetDateOptionAllWaitingData,        // 所有等待下载的数据
    CNDBGetDateOptionModelWithUrl,          // 通过url获取单条数据
    CNDBGetDateOptionWaitingModel,          // 第一条等待的数据
    CNDBGetDateOptionLastDownloadingModel,  // 最后一条正在下载的数据
    CNDBGetDateOptionModelWithActivityId,  //通过activityId获取model
};
@interface CNLiveDataBaseManager ()
@property (nonatomic, strong) FMDatabaseQueue *dbQueue;
@end
@implementation CNLiveDataBaseManager
+ (instancetype)shareManager
{
    static CNLiveDataBaseManager *manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    
    return manager;
}
    
- (instancetype)init
{
    if (self = [super init]) {
        [self creatVideoCachesTable];
    }
    
    return self;
}
#pragma mark - 创建一个数据库
- (void)creatVideoCachesTable
{
    // 数据库文件路径
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"CNDownloadVideoCaches.sqlite"];
    // 创建队列对象，内部会自动创建一个数据库, 并且自动打开
    _dbQueue = [FMDatabaseQueue databaseQueueWithPath:path];
    
    [_dbQueue inDatabase:^(FMDatabase *db) {
        // 创表
        BOOL result = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_videoCaches (id integer PRIMARY KEY AUTOINCREMENT, activityId text, contentId text,title text,albumName text,albumId text,img text,shareUrl text,counts text,viewCounts text,actor text,duration text,modelId text,schedule text,channelName text,time text,url text, resumeData blob, totalFileSize integer, tmpFileSize integer, state integer, progress float, lastSpeedTime double, intervalFileSize integer, lastStateTime integer, fileSize text)"];
        if (![db columnExists:@"channelName" inTableWithName:@"t_videoCaches"] ) { //新添字段,先判断数据里有没有,没有,添加
            NSString *channelName = [NSString stringWithFormat:@"ALTER TABLE %@ ADD %@ INTEGER",@"t_videoCaches",@"channelName"];
            BOOL isSuccess = [db executeUpdate:channelName];
            if (isSuccess) {
                NSLog(@"插入成功");
            }else {
                NSLog(@"插入失败");
            }
        }
        if (result) {
            NSLog(@"音频缓存数据表创建成功");
        }else {
            NSLog(@"音频缓存数据表创建失败");
        }
    }];
}
    
#pragma mark - 插入一条数据
- (void)insertModel:(CNLiveAlbumAudioListModel *)model
{
    [_dbQueue inDatabase:^(FMDatabase *db) {
        BOOL result = [db executeUpdate:@"INSERT INTO t_videoCaches (activityId,contentId,title,albumName,albumId,img,shareUrl,counts,viewCounts,actor,duration,modelId,schedule,channelName,time,url, resumeData, totalFileSize, tmpFileSize, state, progress, lastSpeedTime, intervalFileSize, lastStateTime, fileSize) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,?)", model.activityId?model.activityId :[NSNull null],model.contentId?model.contentId:[NSNull null], model.title?model.title:[NSNull null],model.albumName ? model.albumName:[NSNull null],model.albumId?model.albumId:[NSNull null],model.img?model.img:[NSNull null],model.shareUrl?model.shareUrl:[NSNull null],model.counts?model.counts:[NSNull null],model.viewCounts?model.viewCounts:[NSNull null],model.actor ? model.actor:[NSNull null],model.duration ? model.duration:[NSNull null],model.modelId ?model.modelId :[NSNull null],model.schedule ?model.schedule:[NSNull null],model.channelName ? model.channelName:[NSNull null],model.time ? model.time:[NSNull null],model.url, model.resumeData, [NSNumber numberWithInteger:model.totalFileSize], [NSNumber numberWithInteger:model.tmpFileSize], [NSNumber numberWithInteger:model.state], [NSNumber numberWithFloat:model.progress], [NSNumber numberWithDouble:0], [NSNumber numberWithInteger:0], [NSNumber numberWithInteger:0],model.fileSize];
        if (result) {
            NSLog(@"插入成功：%@", model.title);
        }else {
            NSLog(@"插入失败：%@", model.title);
        }
    }];
}
#pragma mark - 根据url获取单条数据
- (CNLiveAlbumAudioListModel *)getModelWithUrl:(NSString *)url
    {
        return [self getModelWithOption:CNDBGetDateOptionModelWithUrl url:url activityId:nil];
    }
#pragma mark - 根据activityId获取Model
- (CNLiveAlbumAudioListModel *)getModelwithActivityId:(NSString *)activityId {
    return [self getModelWithOption:CNDBGetDateOptionModelWithActivityId url:nil activityId:activityId];
}
#pragma  mark - 获取第一条等待的数据
- (CNLiveAlbumAudioListModel *)getWaitingModel
    {
        return [self getModelWithOption:CNDBGetDateOptionWaitingModel url:nil activityId:nil];
    }
#pragma mark - 获取正在下载的数据
- (CNLiveAlbumAudioListModel *)getLastDownloadingModel
    {
        return [self getModelWithOption:CNDBGetDateOptionLastDownloadingModel url:nil activityId:nil];
    }
    
#pragma mark - 获取所有数据
- (NSArray<CNLiveAlbumAudioListModel *> *)getAllCacheData
    {
        return [self getDateWithOption:CNDBGetDateOptionAllCacheData];
    }
#pragma mark - 根据lastStateTime倒叙获取所有正在下载的数据
- (NSArray<CNLiveAlbumAudioListModel *> *)getAllDownloadingData
    {
        return [self getDateWithOption:CNDBGetDateOptionAllDownloadingData];
    }
#pragma mark - 获取所有下载完成的数据
- (NSArray<CNLiveAlbumAudioListModel *> *)getAllDownloadedData
    {
        return [self getDateWithOption:CNDBGetDateOptionAllDownloadedData];
    }
#pragma mark - 获取所有未下载完成的数据
- (NSArray<CNLiveAlbumAudioListModel *> *)getAllUnDownloadedData
    {
        return [self getDateWithOption:CNDBGetDateOptionAllUnDownloadedData];
    }
#pragma mark - 获取所有等待下载的数据
- (NSArray<CNLiveAlbumAudioListModel *> *)getAllWaitingData
    {
        return [self getDateWithOption:CNDBGetDateOptionAllWaitingData];
    }
#pragma mark - 获取单条数据
- (CNLiveAlbumAudioListModel *)getModelWithOption:(CNDBGetDateOption)option url:(NSString *)url activityId:(NSString *)activityId
    {
        __block CNLiveAlbumAudioListModel *model = nil;
        
        [_dbQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *resultSet;
            switch (option) {
                case CNDBGetDateOptionModelWithUrl:
                resultSet = [db executeQuery:@"SELECT * FROM t_videoCaches WHERE url = ?", url];
                break;
                
                case CNDBGetDateOptionWaitingModel:
                resultSet = [db executeQuery:@"SELECT * FROM t_videoCaches WHERE state = ? order by lastStateTime asc limit 0,1", [NSNumber numberWithInteger:CNDownloadStateWaiting]];
                break;
                
                case CNDBGetDateOptionLastDownloadingModel:
                resultSet = [db executeQuery:@"SELECT * FROM t_videoCaches WHERE state = ? order by lastStateTime desc limit 0,1", [NSNumber numberWithInteger:CNDownloadStateDownloading]];
                break;
                case CNDBGetDateOptionModelWithActivityId:
                resultSet = [db executeQuery:@"SELECT * FROM t_videoCaches WHERE activityId = ?", activityId];
                break;
                default:
                break;
            }
            
            while ([resultSet next]) {
                model = [[CNLiveAlbumAudioListModel alloc] initWithFMResultSet:resultSet];
            }
        }];
        
        return model;
    }
#pragma mark - 获取数据集合
- (NSArray<CNLiveAlbumAudioListModel *> *)getDateWithOption:(CNDBGetDateOption)option
    {
        __block NSArray<CNLiveAlbumAudioListModel *> *array = nil;
        
        [_dbQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *resultSet;
            switch (option) {
                
                case CNDBGetDateOptionAllCacheData:
                resultSet = [db executeQuery:@"SELECT * FROM t_videoCaches"];
                break;
                
                case CNDBGetDateOptionAllDownloadingData:
                resultSet = [db executeQuery:@"SELECT * FROM t_videoCaches WHERE state = ? order by lastStateTime desc", [NSNumber numberWithInteger:CNDownloadStateDownloading]];
                break;
                
                case CNDBGetDateOptionAllDownloadedData:
                resultSet = [db executeQuery:@"SELECT * FROM t_videoCaches WHERE state = ?", [NSNumber numberWithInteger:CNDownloadStateFinish]];
                break;
                
                case CNDBGetDateOptionAllUnDownloadedData:
                resultSet = [db executeQuery:@"SELECT * FROM t_videoCaches WHERE state != ?", [NSNumber numberWithInteger:CNDownloadStateFinish]];
                break;
                
                case CNDBGetDateOptionAllWaitingData:
                resultSet = [db executeQuery:@"SELECT * FROM t_videoCaches WHERE state = ?", [NSNumber numberWithInteger:CNDownloadStateWaiting]];
                break;
                
                default:
                break;
            }
            
            NSMutableArray *tmpArr = [NSMutableArray array];
            while ([resultSet next]) {
                [tmpArr addObject:[[CNLiveAlbumAudioListModel alloc] initWithFMResultSet:resultSet]];
            }
            array = tmpArr;
        }];
        
        return array;
    }
#pragma mark - 更新数据
- (void)updateWithModel:(CNLiveAlbumAudioListModel *)model option:(CNDBUpdateOption)option
    {
        [_dbQueue inDatabase:^(FMDatabase *db) {
            if (option & CNDBUpdateOptionState) {
                //根据url 更新state数据
                [self postStateChangeNotificationWithFMDatabase:db model:model];
                [db executeUpdate:@"UPDATE t_videoCaches SET state = ?,url = ? WHERE activityId = ?", [NSNumber numberWithInteger:model.state], model.url,model.activityId];
            }
            if (option & CNDBUpdateOptionLastStateTime) {
                [db executeUpdate:@"UPDATE t_videoCaches SET lastStateTime = ?,url = ? WHERE activityId = ?", [NSNumber numberWithInteger:[CNLiveTimeTools getTimeStampWithDate:[NSDate date]]], model.url,model.activityId];
            }
            if (option & CNDBUpdateOptionResumeData) {
                [db executeUpdate:@"UPDATE t_videoCaches SET resumeData = ?,url = ? WHERE activityId = ?", model.resumeData, model.url,model.activityId];
            }
            if (option & CNDBUpdateOptionProgressData) {
                [db executeUpdate:@"UPDATE t_videoCaches SET tmpFileSize = ?, totalFileSize = ?, progress = ?, lastSpeedTime = ?, intervalFileSize = ?,url = ? WHERE activityId = ?", [NSNumber numberWithInteger:model.tmpFileSize], [NSNumber numberWithFloat:model.totalFileSize], [NSNumber numberWithFloat:model.progress], [NSNumber numberWithDouble:model.lastSpeedTime], [NSNumber numberWithInteger:model.intervalFileSize], model.url,model.activityId];
            }
            if (option & CNDBUpdateOptionAllParam) {
                [self postStateChangeNotificationWithFMDatabase:db model:model];
                [db executeUpdate:@"UPDATE t_videoCaches SET resumeData = ?, totalFileSize = ?, tmpFileSize = ?, progress = ?, state = ?, lastSpeedTime = ?, intervalFileSize = ?, lastStateTime = ? ,url = ? WHERE activityId = ?", model.resumeData, [NSNumber numberWithInteger:model.totalFileSize], [NSNumber numberWithInteger:model.tmpFileSize], [NSNumber numberWithFloat:model.progress], [NSNumber numberWithInteger:model.state], [NSNumber numberWithDouble:model.lastSpeedTime], [NSNumber numberWithInteger:model.intervalFileSize], [NSNumber numberWithInteger:[CNLiveTimeTools getTimeStampWithDate:[NSDate date]]], model.url,model.activityId];
            }
        }];
    }
    
    
#pragma mark - 状态改变通知
- (void)postStateChangeNotificationWithFMDatabase:(FMDatabase *)db model:(CNLiveAlbumAudioListModel *)model
    {
        // 原状态
        //t_videoCaches创建的表名  where通过什么查询 通过url查询state
        NSInteger oldState = [db intForQuery:@"SELECT state FROM t_videoCaches WHERE activityId = ?", model.activityId];
        
        if (oldState != model.state && oldState != CNDownloadStateFinish) {
            // 状态变更通知
            [[NSNotificationCenter defaultCenter] postNotificationName:WjjAudioDownloadStateChangeNotification object:model];
        }
    }
#pragma mark -  删除数据库数据
- (void)deleteModelWithUrl:(NSString *)activityId
    {
        [_dbQueue inDatabase:^(FMDatabase *db) { // where 后面跟的是条件
            BOOL result = [db executeUpdate:@"DELETE FROM t_videoCaches WHERE activityId = ?", activityId];
            if (result) {
                //            HWLog(@"删除成功：%@", url);
            }else {
                NSLog(@"删除失败：%@", activityId);
            }
        }];
    }
    

@end

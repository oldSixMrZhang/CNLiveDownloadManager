//
//  CNLiveDownloadManager.h
//  CNLiveDownloadManager
//
//  Created by 殷巧娟 on 2019/6/1.
//

#import <Foundation/Foundation.h>
@class CNLiveAlbumAudioListModel;
NS_ASSUME_NONNULL_BEGIN
@interface CNLiveAudioDownloadManager : NSObject
// 初始化下载单例，若之前程序杀死时有正在下的任务，会自动恢复下载
+ (instancetype)shareManager;
    // 开始下载
- (void)startDownloadTask:(CNLiveAlbumAudioListModel *)model;
    
    // 暂停下载
- (void)pauseDownloadTask:(CNLiveAlbumAudioListModel *)model;
    
    // 删除下载任务及本地缓存
- (void)deleteTaskAndCache:(CNLiveAlbumAudioListModel *)model;
    //全部暂停
- (void)pauseAllDownloadTask:(BOOL)isNoHaveNet;
    //全部开始
- (void)startAllDownloadTask:(BOOL)isHaveNoNet;
    @property (nonatomic, assign) BOOL allowsCellularAccess;             // 是否允许蜂窝网络下载
    @property (nonatomic, assign) BOOL isloading; //yes表示有请求download的url在进行
- (void)getDownloadUrl:(CNLiveAlbumAudioListModel *)model;
@end

NS_ASSUME_NONNULL_END

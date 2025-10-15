//
//  CNLiveDataBaseManager.h
//  CNLiveDownloadManager
//
//  Created by 殷巧娟 on 2019/6/1.
//

#import <Foundation/Foundation.h>
@class CNLiveAlbumAudioListModel;
NS_ASSUME_NONNULL_BEGIN
typedef NS_OPTIONS(NSUInteger, CNDBUpdateOption) {
    CNDBUpdateOptionState         = 1 << 0,  // 更新状态
    CNDBUpdateOptionLastStateTime = 1 << 1,  // 更新状态最后改变的时间
    CNDBUpdateOptionResumeData    = 1 << 2,  // 更新下载的数据
    CNDBUpdateOptionProgressData  = 1 << 3,  // 更新进度数据（包含tmpFileSize、totalFileSize、progress、intervalFileSize、lastSpeedTime）
    CNDBUpdateOptionAllParam      = 1 << 4   // 更新全部数据
};
@interface CNLiveDataBaseManager : NSObject
    // 获取单例
+ (instancetype)shareManager;
    // 插入数据
- (void)insertModel:(CNLiveAlbumAudioListModel *)model;
    
    // 获取数据
- (CNLiveAlbumAudioListModel *)getModelWithUrl:(NSString *)url;    // 根据url获取数据
- (CNLiveAlbumAudioListModel *)getWaitingModel;                    // 获取第一条等待的数据
- (CNLiveAlbumAudioListModel *)getLastDownloadingModel;            // 获取最后一条正在下载的数据
- (NSArray<CNLiveAlbumAudioListModel *> *)getAllCacheData;         // 获取所有数据
- (NSArray<CNLiveAlbumAudioListModel *> *)getAllDownloadingData;   // 根据lastStateTime倒叙获取所有正在下载的数据
- (NSArray<CNLiveAlbumAudioListModel *> *)getAllDownloadedData;    // 获取所有下载完成的数据
- (NSArray<CNLiveAlbumAudioListModel *> *)getAllUnDownloadedData;  // 获取所有未下载完成的数据（包含正在下载、等待、暂停、错误）
- (NSArray<CNLiveAlbumAudioListModel *> *)getAllWaitingData;       // 获取所有等待下载的数据
- (CNLiveAlbumAudioListModel *)getModelwithActivityId:(NSString *)activityId; //根据ativityId获取数据
    // 更新数据
- (void)updateWithModel:(CNLiveAlbumAudioListModel *)model option:(CNDBUpdateOption)option;
    
    // 删除数据
- (void)deleteModelWithUrl:(NSString *)activityId;
@end

NS_ASSUME_NONNULL_END

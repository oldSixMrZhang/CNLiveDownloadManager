//
//  CNLiveAlbumAudioListModel.h
//  CNLiveDownloadManager
//
//  Created by 殷巧娟 on 2019/6/1.
//

#import <Foundation/Foundation.h>
#import "CNLiveAlbumMsgModel.h"
#import <FMDB/FMDB.h>
NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, CNDownloadState) {
    CNDownloadStateDefault = 0,  // 默认
    CNDownloadStateDownloading,  // 正在下载
    CNDownloadStateWaiting,      // 等待
    CNDownloadStatePaused,       // 暂停
    CNDownloadStateFinish,       // 完成
    CNDownloadStateError,        // 错误
    CNDownloadStatePausedNoNetwork,    //无网的时候暂停和退到后台暂停
};
typedef enum : NSUInteger {
    CNAPDetailHeaderNoneBtn = 0,     //无
    CNAPDetailHeaderCatalogueBtn,    //目录
    CNAPDetailHeaderPreviousBtn,     //上一曲
    CNAPDetailHeaderPlayBtn,         //播放
    CNAPDetailHeaderPauseBtn,        //暂停
    CNAPDetailHeaderNextBtn ,        //下一曲
    CNAPDetailHeaderDownloadBtn      //下载
} CNAudioPlayerDetailHeaderBtnType;
@interface CNLiveAlbumAudioListModel : NSObject
@property (nonatomic, copy) NSString *activityId; //活动ID
@property (nonatomic, copy) NSString *title; //标题名称
@property (nonatomic, copy) NSString *albumId; //专辑ID
@property (nonatomic, copy) NSString *albumName; //专辑名称
@property (nonatomic, copy) NSString *actor; //作者
@property (nonatomic, copy) NSString *modelId; //类型ID,5是音频
@property (nonatomic, copy) NSString *time;
@property (nonatomic, copy) NSString *img;
@property (nonatomic, copy) NSString *counts; //后面标题号
@property (nonatomic, copy) NSString *viewCounts; //人数
@property (nonatomic, copy) NSString *schedule; //播放长度
@property (nonatomic, copy) NSString *comments; //评论数
@property (nonatomic, copy) NSString *contentId;
@property (nonatomic, copy) NSString *duration; //时长
@property (nonatomic, copy) NSString *shareUrl;
@property (nonatomic, copy)   NSString   *   aid;          //专辑ID
@property (nonatomic, copy)   NSString   *   poster;       //封面图
@property (nonatomic, copy)   NSString   *   channelName;  //
    // 播放详情接口
@property (nonatomic, strong) CNLiveAlbumMsgModel  * album;        //专辑
@property (nonatomic, copy)   NSString   *   desc;         //描述
@property (nonatomic, copy)   NSString   *   model;        //
@property (nonatomic, copy)   NSString   *   publishTime;  //
@property (nonatomic, copy)   NSString   *   siteId;       //
@property (nonatomic, copy)   NSString   *   subTitle;
@property (nonatomic, copy)   NSString *isSelected; //是否被播放过
    // 历史记录
@property (nonatomic, copy) NSString *recordId;
@property (nonatomic, copy) NSString *activeId;
@property (nonatomic, copy) NSString *recent;
@property (nonatomic, copy) NSString *sid;
@property (nonatomic, copy) NSString *albumImg;
@property (nonatomic, copy) NSString *number; //展示前面的数字,自己加的
@property (nonatomic, copy) NSString *isCellSelected; //cell是否被选中
    //下载的数据
@property (nonatomic, copy) NSString *localPath;            // 下载完成路径
@property (nonatomic, copy) NSString *url;                  // url
@property (nonatomic, strong) NSData *resumeData;           // 下载的数据
@property (nonatomic, assign) CGFloat progress;             // 下载进度
@property (nonatomic, assign) CNDownloadState state;        // 下载状态
@property (nonatomic, assign) NSUInteger totalFileSize;     // 文件总大小
@property (nonatomic, assign) NSUInteger tmpFileSize;       // 下载大小
@property (nonatomic, assign) NSUInteger speed;             // 下载速度
@property (nonatomic, assign) NSTimeInterval lastSpeedTime; // 上次计算速度时的时间戳
@property (nonatomic, assign) NSUInteger intervalFileSize;  // 计算速度时间内下载文件的大小
@property (nonatomic, assign) NSUInteger lastStateTime;     // 记录任务加入准备下载的时间（点击默认、暂停、失败状态），用于计算开始、停止任务的先后顺序
@property (nonatomic, copy) NSString *fileSize; //服务器返的文件大小
    
    // 根据数据库查询结果初始化
- (instancetype)initWithFMResultSet:(FMResultSet *)resultSet;
@end

NS_ASSUME_NONNULL_END

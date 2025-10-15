//
//  CNLiveVodUrlUtil.h
//  CNLiveDownloadManager
//
//  Created by 殷巧娟 on 2019/6/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CNLiveVodUrlUtil : NSObject
+ (instancetype)manager;

/**
 获取点播内容url
 
 @param vId 内容id
 @param channelName 频道名称
 @param sid UserId
 @param playType 音频:"a" 视频:"v"
 @param tag 非必传
 @param completeBlock 回调
 */
- (void)getVodUrlWithVid:(NSString *)vId channelName:(NSString *)channelName sid:(NSString *)sid playType:(NSString *)playType tag:(NSString *)tag completeBlock:(void(^)(NSString *vodUrl))completeBlock;
@end

NS_ASSUME_NONNULL_END

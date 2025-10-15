//
//  CNLiveAlbumMsgModel.h
//  CNLiveDownloadManager
//
//  Created by 殷巧娟 on 2019/6/1.
//

#import <Foundation/Foundation.h>
@class CNLiveAlbumMsgSpModel;
NS_ASSUME_NONNULL_BEGIN

@interface CNLiveAlbumMsgModel : NSObject
@property (nonatomic, copy) NSString *albumId;
@property (nonatomic, copy) NSString *albumImg; //图片地址
@property (nonatomic, copy) NSString *albumName; //标题
@property (nonatomic, copy) NSString *desc; //描述
@property (nonatomic, copy) NSString *actor;
@property (nonatomic, copy) NSString *time; //时间戳
@property (nonatomic, copy) NSString *episodeNow; //总集数
@property (nonatomic, strong) CNLiveAlbumMsgSpModel *sp; //下面简介
@property (nonatomic, copy) NSString *subscriptions;
@property (nonatomic, copy) NSString *subscribe;
@property (nonatomic, copy) NSString *episodeLast; //最后一次播放的章节数
@property (nonatomic, copy) NSString *contentIdLast;
- (CGFloat)setRowHeight;
@end
@interface CNLiveAlbumMsgSpModel : NSObject
@property (nonatomic, copy) NSString *spName; //
@property (nonatomic, copy) NSString *spId; //
@property (nonatomic, copy) NSString *spIcon; //
@property (nonatomic, copy) NSString *desc; //
@property (nonatomic, copy) NSString *subscriptions; //
@property (nonatomic, copy) NSString *subscribe; //
@end

NS_ASSUME_NONNULL_END

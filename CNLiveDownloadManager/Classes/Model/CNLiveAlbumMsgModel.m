//
//  CNLiveAlbumMsgModel.m
//  CNLiveDownloadManager
//
//  Created by 殷巧娟 on 2019/6/1.
//

#import "CNLiveAlbumMsgModel.h"
#import <CNLiveBaseKit/CNLiveDefinesHeader.h>
@implementation CNLiveAlbumMsgModel
+ (NSDictionary *)mj_objectClassInArray{
    return @{
             @"sp" : @"CNLiveAlbumMsgSpModel"
             };
}
- (CGFloat)setRowHeight {
    NSDictionary *descAttr = @{NSFontAttributeName:UIFontCNMake(16)};
    CGFloat descHeight = [self.desc boundingRectWithSize:CGSizeMake(KScreenWidth - 20, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin  attributes:descAttr context:nil].size.height;
    return descHeight;
}
@end
@implementation CNLiveAlbumMsgSpModel
    
@end


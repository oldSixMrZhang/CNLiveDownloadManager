//
//  CNLiveVodUrlUtil.m
//  CNLiveDownloadManager
//
//  Created by 殷巧娟 on 2019/6/3.
//

#import "CNLiveVodUrlUtil.h"
#import "CNLiveMediaEditorNetworkManager.h"
#import "CNEnvironmentHeader.h"
#import "CNLiveBusinessTools.h"
#import "NetworkAPIs.h"
@implementation CNLiveVodUrlUtil
+ (instancetype)manager {
    static CNLiveVodUrlUtil *instance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)getVodUrlWithVid:(NSString *)vId channelName:(NSString *)channelName sid:(NSString *)sid playType:(NSString *)playType tag:(NSString *)tag completeBlock:(void(^)(NSString *vodUrl))completeBlock
{
    NSInteger time = [[NSDate date] timeIntervalSince1970];
    NSString *timeString = [NSString stringWithFormat:@"%ld", (long)time];
    
    NSString *timestamp = timeString;
    NSString *appId = AppId;
    
    NSString *uid = [CNLiveBusinessTools getUidForStat:timestamp];
    ////playType @"a": @"v"
    ////
    NSDictionary *parameter1 = @{@"appId": appId,
                                 @"vId": vId?vId:@"",
                                 @"timestamp": timestamp,
                                 @"isHLS": @"1",
                                 @"plat": @"i",
                                 @"playType": playType ? playType: @"",
                                 @"platform_id": [NSBundle mainBundle].bundleIdentifier,
                                 @"channelName": channelName?channelName:@"",
                                 @"tag": tag?tag:@"",
                                 @"from": @"apple", @"sid":sid?sid:@"",
                                 @"uid": uid?uid:@""};
    
    NSString *string1 = [NSString stringWithFormat:@"%@&key=%@", [CNLiveBusinessTools signvalue:parameter1], APPKey];
    NSString *signString1 = [[CNLiveBusinessTools sha1:string1] uppercaseString];
    
    NSString *videourl1 = [NSString stringWithFormat:@"%@?%@&sign=%@", CNGetVodUrl, [CNLiveBusinessTools signvalue:parameter1], signString1];
    
    CNLiveMediaEditorNetworkManager *manager = [[CNLiveMediaEditorNetworkManager alloc] init];
    
    [manager requestGetVideoURL:videourl1 success:^(NSString * _Nullable videoURL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completeBlock) {
                completeBlock(videoURL);
            }
        });
    }];
}

@end

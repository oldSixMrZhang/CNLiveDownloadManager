//
//  CNLiveMediaEditorNetworkManager.h
//  CNLiveDownloadManager
//
//  Created by 殷巧娟 on 2019/6/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CNLiveMediaEditorNetworkManager : NSObject
/**
 *  设置超时时间
 */
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

/**
 *  缓存策略
 */
@property (nonatomic, assign) NSURLRequestCachePolicy cachePolicy;

+ (nonnull CNLiveMediaEditorNetworkManager *)manager;

/**
 *  GET 请求
 *  @param URL
 *  @param parameters 上传参数
 *  @param success 请求成功回调
 *  @param failure 请求失败回调
 */
- (void)requestGetURL:(nullable NSString *)URL
           parameters:(nullable NSDictionary *)parameters
              success:(nullable void (^)(NSURLResponse *_Nullable response, id _Nullable responseObject))success
              failure:(nullable void (^)(NSURLResponse *_Nullable response, NSError *_Nullable  error))failure;

/**
 *  POST 请求
 *  @param URL
 *  @param parameters 上传参数
 *  @param success 请求成功回调
 *  @param failure 请求失败回调
 */
- (void)requestPostURL:(nullable NSString *)URL
            parameters:(nullable NSDictionary *)parameters
               success:(nullable void (^)(NSURLResponse *_Nullable response, id _Nullable responseObject))success
               failure:(nullable void (^)(NSURLResponse *_Nullable response, NSError *_Nullable  error))failure;


/**
 *  用于获取播放地址
 */
- (void)requestGetVideoURL:(nullable NSString *)URL
                   success:(nullable void (^)(NSString *_Nullable videoURL))success;


- (void)destroyNetManager;
@end

NS_ASSUME_NONNULL_END

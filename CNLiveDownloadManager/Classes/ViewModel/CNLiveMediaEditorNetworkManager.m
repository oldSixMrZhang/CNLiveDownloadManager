//
//  CNLiveMediaEditorNetworkManager.m
//  CNLiveDownloadManager
//
//  Created by 殷巧娟 on 2019/6/3.
//

#import "CNLiveMediaEditorNetworkManager.h"
#import "CNLiveMediaEditorRequestSerialization.h"
/**
 *  网络超时时间 默认 60
 */
static  NSTimeInterval TimeoutInterval = 30.0 ;

/**
 *  缓存策略
 *  NSURLRequestUseProtocolCachePolicy // 默认的缓存策略（取决于协议）
 *  NSURLRequestReloadIgnoringLocalCacheData // 忽略缓存，重新请求
 *  NSURLRequestReloadIgnoringLocalAndRemoteCacheData // 未实现
 *  NSURLRequestReloadIgnoringCacheData = NSURLRequestReloadIgnoringLocalCacheData // 忽略缓存，重新请求
 *  NSURLRequestReturnCacheDataElseLoad// 有缓存就用缓存，忽略过期时间！没有缓存就重新请求
 *  NSURLRequestReturnCacheDataDontLoad// 有缓存就用缓存，没有缓存就不发请求，当做请求出错处理（用于离线模式）
 *  NSURLRequestReloadRevalidatingCacheData // 未实现
 */
static NSURLRequestCachePolicy CachePolicy = NSURLRequestUseProtocolCachePolicy;

typedef void(^GetVideoURLSuccessBlock)(NSString *_Nullable videoURL);

@interface CNLiveMediaEditorNetworkManager ()<NSURLSessionDelegate>
{
    BOOL _result;
}

@property (nonatomic, copy) GetVideoURLSuccessBlock successBlock;

@end

@implementation CNLiveMediaEditorNetworkManager

- (void)dealloc
{
    //    D_NSLog(@">>>>>>>>>>>>>> CNLiveKSYNetworkManager dealloc");
}

- (void)destroyNetManager {
    self.successBlock = nil;
    //    D_NSLog(@">>>>>>>>>>>>>> destroyNetManager");
    
}

+ (CNLiveMediaEditorNetworkManager *)manager
{
    static CNLiveMediaEditorNetworkManager *manager = nil;
    
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        
        manager = [[CNLiveMediaEditorNetworkManager alloc] init];
        
    });
    
    manager.cachePolicy = CachePolicy;
    
    manager.timeoutInterval = TimeoutInterval;
    
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.cachePolicy = CachePolicy;
        self.timeoutInterval = TimeoutInterval;
    }
    return self;
}

-(void)requestGetURL:(NSString *)URL
          parameters:(NSDictionary *)parameters
             success:(void (^)(NSURLResponse * _Nullable, id _Nullable))success
             failure:(void (^)(NSURLResponse * _Nullable, NSError * _Nullable))failure
{
    NSURLSessionDataTask *task = [self dataTaskWithRequestMethod:@"GET" URLString:URL parameters:parameters success:success failure:failure];
    [task resume];
}

- (void)requestPostURL:(NSString *)URL
            parameters:(NSDictionary *)parameters
               success:(void (^)(NSURLResponse * _Nullable, id _Nullable))success
               failure:(void (^)(NSURLResponse * _Nullable, NSError * _Nullable))failure
{
    NSURLSessionDataTask *task = [self dataTaskWithRequestMethod:@"POST" URLString:URL parameters:parameters success:success failure:failure];
    [task resume];
}

- (void)requestGetVideoURL:(NSString *)URL success:(void (^)(NSString * _Nullable))success {
    
    self.successBlock = success;
    _result = NO;
    
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                          delegate:self
                                                     delegateQueue:[[NSOperationQueue alloc] init]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:URL] cachePolicy:self.cachePolicy timeoutInterval:self.timeoutInterval];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    
    // 启动任务
    [task resume];
}

#pragma mark -
#pragma mark - NSURLSessionDelegate
// 1.接收到服务器的响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    // 允许处理服务器的响应，才会继续接收服务器返回的数据
    completionHandler(NSURLSessionResponseCancel);
    _result = YES;
    self.successBlock([response.URL absoluteString]);
    
}

// 3.请求成功或者失败（如果失败，error有值）
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    // 请求完成,成功或者失败的处理
    
    if (_result) return;
    
    NSString *videoUrl302 = error.userInfo[@"NSErrorFailingURLStringKey"];
    if (!videoUrl302 || ![videoUrl302 isKindOfClass:[NSString class]] || videoUrl302.length <= 0) {
        videoUrl302 = nil;
    }
    self.successBlock(videoUrl302);
    
}


- (NSURLSessionDataTask *)dataTaskWithRequestMethod:(NSString *)method
                                          URLString:(NSString *)URLString
                                         parameters:(NSDictionary *)parameters
                                            success:(void (^)(NSURLResponse * _Nullable, id _Nullable))success
                                            failure:(void (^)(NSURLResponse * _Nullable, NSError * _Nullable))failure
{
    
    if (![URLString isKindOfClass:[NSString class]]) {
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey : @"please enter a valid url"}];
        failure(nil, error);
        return nil;
    }
    
    NSString *newURLString;
    if ([method isEqualToString:@"GET"]) {
        if (parameters) {
            newURLString = [[URLString stringByAppendingString:@"?"] stringByAppendingString:[CNLiveMediaEditorRequestSerialization CNNetPlusQueryStringFromParameters:parameters]];
        }else{
            newURLString = URLString;
        }
    }else{
        newURLString = URLString;
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:newURLString] cachePolicy:self.cachePolicy timeoutInterval:self.timeoutInterval];
    
    request.HTTPMethod = method;
    
    if([method isEqual:@"POST"]){
        [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        request.HTTPBody =[[CNLiveMediaEditorRequestSerialization CNNetPlusQueryStringFromParameters:parameters] dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    NSURLSessionDataTask *task = [self dataTaskWithRequest:request success:success failure:failure];
    
    return task;
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                                      success:(void (^)(NSURLResponse * _Nullable, id _Nullable))success
                                      failure:(void (^)(NSURLResponse * _Nullable, NSError * _Nullable))failure
{
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                failure(response,error);
            }else{
                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    if (httpResponse.statusCode < 400) {
                        id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                        success(httpResponse,jsonObj);
                    } else {
                        NSError *failureError = [NSError errorWithDomain:NSURLErrorDomain code:httpResponse.statusCode userInfo:httpResponse.allHeaderFields];
                        failure(httpResponse,failureError);
                    }
                } else {
                    failure(response,error);
                }
            }
        });
    }];
    
    return task;
}

- (NSURL *)formatURLString:(NSString *)url
{
    NSURL *urlString = [NSURL URLWithString:[url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    return urlString;
}

@end


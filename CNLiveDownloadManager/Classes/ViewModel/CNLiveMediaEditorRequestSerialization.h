//
//  CNLiveMediaEditorRequestSerialization.h
//  CNLiveBaseKit
//
//  Created by 殷巧娟 on 2019/6/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CNLiveMediaEditorRequestSerialization : NSObject
+ (nullable NSString *)CNNetPlusQueryStringFromParameters:(nullable NSDictionary *)parameters;
@end

NS_ASSUME_NONNULL_END

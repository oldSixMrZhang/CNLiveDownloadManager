//
//  CNLiveMediaEditorRequestSerialization.m
//  CNLiveBaseKit
//
//  Created by 殷巧娟 on 2019/6/3.
//

#import "CNLiveMediaEditorRequestSerialization.h"

@interface CNLiveMediaEditorRequestSerialization ()
@property (readwrite, nonatomic, strong) id value;

@property (readwrite, nonatomic, strong) id field;
@end

@implementation CNLiveMediaEditorRequestSerialization
- (id)initWithField:(id)field value:(id)value
{
    self = [super init];
    
    if (self) {
        
        self.field = field;
        
        self.value = value;
    }
    
    return self;
    
}
#pragma mark -

FOUNDATION_EXPORT NSArray * CNNetPlusQueryStringPairsFromDictionary(NSDictionary *dictionary);
FOUNDATION_EXPORT NSArray * CNNetPlusQueryStringPairsFromKeyAndValue(NSString *key, id value);

+ (NSString *)CNNetPlusQueryStringFromParameters:(NSDictionary *)parameters
{
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (CNLiveMediaEditorRequestSerialization *pair in CNNetPlusQueryStringPairsFromDictionary(parameters)) {
        [mutablePairs addObject:[pair URLEncodedStringValue]];
    }
    return [mutablePairs componentsJoinedByString:@"&"];
}

NSArray * CNNetPlusQueryStringPairsFromDictionary(NSDictionary *dictionary)
{
    return CNNetPlusQueryStringPairsFromKeyAndValue(nil, dictionary);
}

/**
 *  处理上传参数
 */
NSArray * CNNetPlusQueryStringPairsFromKeyAndValue(NSString *key, id value)
{
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];
    
    //排序方式
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];
    
    if ([value isKindOfClass:[NSDictionary class]]) {   //字典
        NSDictionary *dictionary = value;
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[sortDescriptor]]) {
            id nestedValue = dictionary[nestedKey];
            if (nestedKey) {
                [mutableQueryStringComponents addObjectsFromArray:CNNetPlusQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
            }
        }
    }
    
    else if ([value isKindOfClass:[NSArray class]]){   //数组
        NSArray *array = value;
        for (id nestedValue in array) {
            [mutableQueryStringComponents addObjectsFromArray:CNNetPlusQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }
    }else if ([value isKindOfClass:[NSSet class]]){   //集合
        NSSet *set = value;
        for (id obj in [set sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            [mutableQueryStringComponents addObjectsFromArray:CNNetPlusQueryStringPairsFromKeyAndValue(key, obj)];
        }
    }else{  //其他类型
        [mutableQueryStringComponents addObject:[[CNLiveMediaEditorRequestSerialization alloc] initWithField:key value:value]];
    }
    
    return mutableQueryStringComponents;
}

static NSString * CNNetPlusPercentEscapedStringFromString(NSString *string) {
    static NSString * const kCNNetPlusCharactersGeneralDelimitersToEncode = @":#[]@"; // does not include "?" or "/" due to RFC 3986 - Section 3.4
    static NSString * const kCNNetPlusCharactersSubDelimitersToEncode = @"!$&'()*+,;=";
    
    NSMutableCharacterSet * allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowedCharacterSet removeCharactersInString:[kCNNetPlusCharactersGeneralDelimitersToEncode stringByAppendingString:kCNNetPlusCharactersSubDelimitersToEncode]];
    
    
    static NSUInteger const batchSize = 50;
    
    NSUInteger index = 0;
    NSMutableString *escaped = @"".mutableCopy;
    
    while (index < string.length) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wgnu"
        NSUInteger length = MIN(string.length - index, batchSize);
#pragma GCC diagnostic pop
        NSRange range = NSMakeRange(index, length);
        
        range = [string rangeOfComposedCharacterSequencesForRange:range];
        
        NSString *substring = [string substringWithRange:range];
        NSString *encoded = [substring stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
        [escaped appendString:encoded];
        
        index += range.length;
    }
    
    return escaped;
}

- (NSString *)URLEncodedStringValue {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return CNNetPlusPercentEscapedStringFromString([self.field description]);
    } else {
        return [NSString stringWithFormat:@"%@=%@", CNNetPlusPercentEscapedStringFromString([self.field description]), CNNetPlusPercentEscapedStringFromString([self.value description])];
    }
}

@end

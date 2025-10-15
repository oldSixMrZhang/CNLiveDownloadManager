//
//  NSURLSession+CNLiveCorrectedResumeData.h
//  CNLiveBaseKit
//
//  Created by 殷巧娟 on 2019/6/3.
//



NS_ASSUME_NONNULL_BEGIN

@interface NSURLSession (CNLiveCorrectedResumeData)
- (NSURLSessionDownloadTask *)downloadTaskWithCorrectResumeData:(NSData *)resumeData;
@end

NS_ASSUME_NONNULL_END

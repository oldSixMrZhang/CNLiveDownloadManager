//
//  CNLiveAlbumAudioListModel.m
//  CNLiveDownloadManager
//
//  Created by 殷巧娟 on 2019/6/1.
//

#import "CNLiveAlbumAudioListModel.h"
#import "MJExtension.h"
@implementation CNLiveAlbumAudioListModel
+ (NSDictionary *)mj_replacedKeyFromPropertyName
{
    return @{
            @"recordId":@"id",
            };
}
- (NSString *)localPath {
    if (!_localPath) {
        if (_url && ![_url isEqualToString:@"<null>"]) {
            NSString *fileName = [_url substringFromIndex:[_url rangeOfString:@"/" options:NSBackwardsSearch].location + 1];
            NSString *str = [NSString stringWithFormat:@"%@_%@", _activityId, fileName];
            NSString *fileCacheDireCtory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"albumAudioList_%@",_albumId]];
            _localPath = [fileCacheDireCtory stringByAppendingPathComponent:str];
        }
    }
    
    return _localPath ? _localPath: @"";
}
- (instancetype)initWithFMResultSet:(FMResultSet *)resultSet {
    if (!resultSet) return nil;
    _activityId = [NSString stringWithFormat:@"%@",[resultSet objectForColumn:@"activityId"]];
    _contentId = [NSString stringWithFormat:@"%@", [resultSet objectForColumn:@"contentId"]];
    _title = [NSString stringWithFormat:@"%@", [resultSet objectForColumn:@"title"]];
    _albumName = [NSString stringWithFormat:@"%@",[resultSet objectForColumn:@"albumName"]];
    _albumId = [NSString stringWithFormat:@"%@",[resultSet objectForColumn:@"albumId"]];
    _img = [NSString stringWithFormat:@"%@",[resultSet objectForColumn:@"img"]];
    _shareUrl = [NSString stringWithFormat:@"%@",[resultSet objectForColumn:@"shareUrl"]];
    _counts = [NSString stringWithFormat:@"%@",[resultSet objectForColumn:@"counts"]];
    _viewCounts = [NSString stringWithFormat:@"%@",[resultSet objectForColumn:@"viewCounts"]];
    _actor = [NSString stringWithFormat:@"%@",[resultSet objectForColumn:@"actor"]];
    _duration = [NSString stringWithFormat:@"%@",[resultSet objectForColumn:@"duration"]];
    _modelId = [NSString stringWithFormat:@"%@",[resultSet objectForColumn:@"modelId"]];
    _schedule = [NSString stringWithFormat:@"%@",[resultSet objectForColumn:@"schedule"]];
    _channelName = [NSString stringWithFormat:@"%@",[resultSet objectForColumn:@"channelName"]];
    _time = [NSString stringWithFormat:@"%@",[resultSet objectForColumn:@"time"]];
    _url = [NSString stringWithFormat:@"%@", [resultSet objectForColumn:@"url"]];
    _resumeData = [resultSet dataForColumn:@"resumeData"];
    _totalFileSize = [[resultSet objectForColumn:@"totalFileSize"] integerValue];
    _tmpFileSize = [[resultSet objectForColumn:@"tmpFileSize"] integerValue];
    _state = [[resultSet objectForColumn:@"state"] integerValue];
    _progress = [[resultSet objectForColumn:@"progress"] floatValue];
    _lastSpeedTime = [resultSet doubleForColumn:@"lastSpeedTime"];
    _intervalFileSize = [[resultSet objectForColumn:@"intervalFileSize"] integerValue];
    _lastStateTime = [[resultSet objectForColumn:@"lastStateTime"] integerValue];
    _fileSize = [NSString stringWithFormat:@"%@",[resultSet objectForColumn:@"fileSize"]];
    
    return self;
}

@end

#import <Foundation/Foundation.h>

@interface AgoraRtcEngineKit : NSObject
+ (instancetype)sharedEngineWithAppId:(NSString *)appId delegate:(id)delegate;
@end

%hook AgoraRtcEngineKit

+ (instancetype)sharedEngineWithAppId:(NSString *)appId delegate:(id)delegate {
    if (appId) {
        appId = @"b0d94e86457a4018af828cc0ff4eb9be";
    }

    return %orig(appId, delegate);
}

%end

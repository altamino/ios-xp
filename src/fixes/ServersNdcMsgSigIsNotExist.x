// Original: https://github.com/altamino/ServersNdcMsgSigIsNotExist/blob/main/Tweak.x
// MIT Licensed


#import <Foundation/Foundation.h>

@interface NSError (NDCAdditions)
- (NSInteger)statusCodeNDCAPI;
@end

%hook NSData

- (BOOL)verifyRSASignature:(id)signature certData:(id)certificate {
    NSLog(@"[ServersNdcMsgSigIsNotExist] verifyRSASignature:certData: called. Forcing validation success!");
    return YES;
}

%end

%hook NSError

- (NSDictionary *)userInfo {
    NSDictionary *orig = %orig;
    if (orig) {
        id statusCode = orig[@"kNDCServiceAPIStatusCodeKey"];
        if (statusCode && [statusCode respondsToSelector:@selector(integerValue)] && [statusCode integerValue] == 270) {
            NSMutableDictionary *patchedUserInfo = [orig mutableCopy];

            patchedUserInfo[@"kNDCErrorUserInfoResponseVerifiedKey"] = @YES;

            NSLog(@"[ServersNdcMsgSigIsNotExist] Patched kNDCErrorUserInfoResponseVerifiedKey to YES for API status 270");
            return [patchedUserInfo copy];
        }
    }
    return orig;
}

%end

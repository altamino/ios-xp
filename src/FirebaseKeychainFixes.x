#import <Foundation/Foundation.h>

//
// interfaces
//
@interface KeychainItemWrapper : NSObject
- (id)initWithIdentifier:(NSString *)identifier accessGroup:(NSString *)accessGroup;
@end

@interface FIRRemoteConfigValue : NSObject
- (NSString *)stringValue;
@end


//
// keychain fix
//
%hook KeychainItemWrapper
- (id)initWithIdentifier:(NSString *)identifier accessGroup:(NSString *)accessGroup {
    return %orig(identifier, nil);
}
%end


//
// firebase remote config bypass
//
%hook FIRRemoteConfigValue
- (NSString *)stringValue {
    NSString *originalValue = %orig;
    if (originalValue && [originalValue isEqualToString:@"false"]) {
        return @"true";
    }
    return originalValue;
}
%end

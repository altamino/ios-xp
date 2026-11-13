#import <Foundation/Foundation.h>

%hook ALSdk

- (BOOL)isEnabled {
    return NO;
}

%end

%hook NDCAccount

- (BOOL)shouldShowTypeOfAd:(NSInteger)type {
    return NO;
}

- (BOOL)adsEnabled {
    return NO;
}

%end

%hook NSUserDefaults

- (BOOL)boolForKey:(NSString *)defaultName {
    if ([defaultName isEqualToString:@"ndc_showAdsOnChatScreen"]) {
        return NO;
    }
    return %orig;
}

%end

%hook NDCComposeAdvancedBlogViewController

- (void)setupAds {
    // Do nothing
}

- (void)refreshAds {
    // Do nothing
}

%end

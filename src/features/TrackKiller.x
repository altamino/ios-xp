#import <Foundation/Foundation.h>

static NSURLRequest *blockedRequest;
static NSArray<NSString *> *trackersURLs;

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {
    NSURL *url = request.URL;
    NSString *host = url.host;

    if (host) {
        for (NSString *tracker in trackersURLs) {
            if ([host containsString:tracker]) {
                return %orig(blockedRequest, completionHandler);
            }
        }
    }

    return %orig;
}

%end

%hook NDCRTCEngine

- (id)initWithURLs:(NSArray<NSURL *> *)urls {
    NSURL *firstURL = urls.firstObject;
    if (firstURL.host && [firstURL.host containsString:@"ws-log"]) {
        return nil;
    }
    return %orig;
}

%end

%hook Tapjoy

+ (id)connect:(NSString *)sdkKey {
    return nil;
}

%end

%hook NDCRTCAnalzyerWritter

- (id)initWithEngine:(id)engine {
    return nil;
}

%end

%hook APMMeasurement

- (BOOL)isEnabled {
    return NO;
}

%end


%ctor {
    blockedRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost"]];
    trackersURLs = @[
        @"assemblyexchange.com",
        @"amazon-adsystem.com",
        @"media-lab.ai",
        @"scorecardresearch.com",
        @"applovin.com",
        @"applvn.com",
        @"facebook.com",
        @"whisper.sh",
        @"vungle.com",
        @"doubleclick.net",
        @"fundingchoicesmessages",
        @"firebaselogging"
    ];


    // Required to hook Swift classes with module prefixes (e.g., "Main.ClassName")
    %init(
        NDCRTCEngine = objc_getClass("Main.NDCRTCEngine"),
        NDCRTCAnalzyerWritter = objc_getClass("Main.NDCRTCAnalzyerWritter")
    );
}

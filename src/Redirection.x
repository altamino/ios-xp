#import <Foundation/Foundation.h>

//
// hostname redirection
//
%hook NSURL
- (id)initWithString:(NSString *)URLString relativeToURL:(NSURL *)baseURL {
	// if (URLString && [URLString containsString:@"service.aminoapps.com"]) {
	//    URLString = [URLString stringByReplacingOccurrencesOfString:@"service.aminoapps.com"
	//                                                         withString:@"dev-service.altamino.top"];
	// }
    if (URLString && [URLString containsString:@"aminoapps.com"]) {
        URLString = [URLString stringByReplacingOccurrencesOfString:@"aminoapps.com"
                                                         withString:@"altamino.top"];
    }
    return %orig(URLString, baseURL);
}
%end

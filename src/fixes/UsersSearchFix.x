#import <UIKit/UIKit.h>

@interface NDCContext : NSObject
- (NSInteger)communityID;
@end

@interface NDCMembersListViewController : UIViewController
- (void)setCommunityID:(NSInteger)communityId;
- (NDCContext *)ndc_context;
- (void)setQueryDescriptor:(NSObject *)queryDescriptor;
@end

%hook NDCMembersListViewController

- (void)setCommunityID:(NSInteger)communityId {
    %orig(communityId);
}

- (NDCContext *)ndc_context {
    return %orig;
}

- (void)setQueryDescriptor:(NSObject *)queryDescriptor {
    [self setCommunityID:[[self ndc_context] communityID]];
    %orig(queryDescriptor);
}

%end

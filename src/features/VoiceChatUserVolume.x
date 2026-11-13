#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// Forward declarations
@class AgoraRtcEngineKit;
@class NDCRTCAttendee;
@class NDCChatUserActionConfig;
@class NDCChatUserActionController;
@class NDCRTCChatActionHandler;

// Manual interface declaration for NDCRTCAttendee (SDK headers are not available)
// NOTE: Verify these signatures match the real SDK; a mismatch causes unrecognized-selector crashes.
@interface NDCRTCAttendee : NSObject
- (NSInteger)role;
- (NSInteger)uid;
@end

// Interface declarations with method signatures (needed before C functions use them)
@interface AgoraRtcEngineKit : NSObject
+ (instancetype)sharedEngineWithAppId:(id)appId delegate:(id)delegate;
- (void)adjustUserPlaybackSignalVolume:(NSInteger)uid volume:(NSInteger)volume;
@end

@interface NDCChatUserActionConfig : NSObject
- (NDCRTCAttendee *_Nullable)targetAttendee;
- (BOOL)isSelfOpened;
- (BOOL)canShowLocalMuteToggle;
@end

@interface NDCChatUserActionController : UIViewController
- (UILabel *)muteLabel;
- (UISwitch *)muteSwitch;
- (NDCChatUserActionConfig *_Nullable)config;
- (UIView *)contentView;
- (void)volumeSliderValueChanged:(UISlider *)sender;
- (void)updateMuteView;
- (void)viewDidAppear:(BOOL)animated;
- (void)userDidUpdate;
@end

// C function forward declarations
static void HandleVolumeSliderValueChanged(UISlider *slider, id controller);
static void UpdateMuteViewForController(id controller);

// Global state
static AgoraRtcEngineKit *_Nullable agoraRtcEngine = nil;
static NSMutableDictionary<NSNumber *, NSNumber *> *_Nullable usersVolume = nil;

// Per-instance associated-object key for the mute stack view (replaces the buggy static)
static char kMuteLineViewKey;

static UIStackView *MuteLineViewFor(id obj) {
    return objc_getAssociatedObject(obj, &kMuteLineViewKey);
}

static void SetMuteLineView(id obj, UIStackView *_Nullable view) {
    objc_setAssociatedObject(obj, &kMuteLineViewKey, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// Simple trampoline for slider target-action (avoids relying on volumeSliderValueChanged
// existing as a method on NDCChatUserActionController — it is orion:new in the original).
@interface SliderActionForwarder : NSObject
@property (nonatomic, weak) id controller;
- (void)sliderValueChanged:(UISlider *)slider;
@end

@implementation SliderActionForwarder
- (void)sliderValueChanged:(UISlider *)slider {
    if (self.controller) {
        HandleVolumeSliderValueChanged(slider, self.controller);
    }
}
@end

static char kSliderForwarderKey;

static void SetSliderForwarder(id controller, SliderActionForwarder *forwarder) {
    objc_setAssociatedObject(controller, &kSliderForwarderKey, forwarder, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// Handles volume slider changes without relying on volumeSliderValueChanged existing
// as a method on NDCChatUserActionController.
static void HandleVolumeSliderValueChanged(UISlider *slider, id controller) {
    NDCChatUserActionConfig *config = [controller config];
    NDCRTCAttendee *attendee = config ? [config targetAttendee] : nil;
    if (!attendee || !agoraRtcEngine) {
        return;
    }

    NSNumber *uid = @([attendee uid]);
    if (!usersVolume) {
        usersVolume = [NSMutableDictionary dictionary];
    }
    usersVolume[uid] = @(slider.value);

    [agoraRtcEngine adjustUserPlaybackSignalVolume:[attendee uid] volume:(NSInteger)slider.value];
}

// Helper that applies mute view layout without relying on updateMuteView existing
// as a method on NDCChatUserActionController (it may not exist in the original SDK class).
static void UpdateMuteViewForController(id controller) {
    UIStackView *stackView = MuteLineViewFor(controller);
    if (!stackView) return;

    stackView.frame = CGRectMake(0, 0, 330, 46);

    UIView *content = [controller respondsToSelector:@selector(contentView)] ? [controller contentView] : nil;
    UILabel *label = [controller respondsToSelector:@selector(muteLabel)] ? [controller muteLabel] : nil;
    CGFloat cx = content ? CGRectGetMidX(content.frame) : 0;
    CGFloat cy = label ? CGRectGetMidY(label.frame) : 0;
    stackView.center = CGPointMake(cx - 10, cy);
}

// MARK: - AgoraRtcEngineKit Hook

%hook AgoraRtcEngineKit

+ (instancetype)sharedEngineWithAppId:(id)appId delegate:(id)delegate {
    id engine = %orig(appId, delegate);
    agoraRtcEngine = engine;
    return engine;
}

%end


// MARK: - NDCChatUserActionConfig Hook

%hook NDCChatUserActionConfig

- (NDCRTCAttendee *_Nullable)targetAttendee {
    return %orig;
}

- (BOOL)isSelfOpened {
    return %orig;
}

- (BOOL)canShowLocalMuteToggle {
    NDCRTCAttendee *attendee = [self targetAttendee];
    if (attendee) {
        return [attendee role] == 1 && ![self isSelfOpened];
    }
    return NO;
}

%end


// MARK: - NDCChatUserActionController Hook

%hook NDCChatUserActionController

- (UILabel *)muteLabel {
    return %orig;
}

- (UISwitch *)muteSwitch {
    return %orig;
}

- (NDCChatUserActionConfig *_Nullable)config {
    return %orig;
}

- (UIView *)contentView {
    return %orig;
}

- (void)viewDidAppear:(BOOL)animated {
    %orig(animated);

    NDCChatUserActionConfig *config = [self config];
    NDCRTCAttendee *attendee = config ? [config targetAttendee] : nil;
    if (!attendee) {
        return;
    }

    if (![config canShowLocalMuteToggle]) {
        return;
    }

    // Remove any previously added mute view for this instance before adding a new one
    UIStackView *existing = MuteLineViewFor(self);
    if (existing) {
        [existing removeFromSuperview];
        SetMuteLineView(self, nil);
    }

    [self.muteLabel setHidden:YES];
    [self.muteSwitch setHidden:YES];

    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.spacing = 10;

    UILabel *label = [[UILabel alloc] init];
    label.text = @"Volume";
    label.textColor = [UIColor systemGrayColor];

    UISlider *slider = [[UISlider alloc] init];
    slider.minimumValue = 0;
    slider.maximumValue = 99;
    slider.minimumTrackTintColor = [UIColor systemBlueColor];

    float savedVolume = 99.0f;
    if (usersVolume) {
        NSNumber *vol = usersVolume[@([attendee uid])];
        if (vol) savedVolume = [vol floatValue];
    }
    slider.value = savedVolume;

    SliderActionForwarder *forwarder = [[SliderActionForwarder alloc] init];
    forwarder.controller = self;
    SetSliderForwarder(self, forwarder);
    [slider addTarget:forwarder action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];

    [stackView addArrangedSubview:label];
    [stackView addArrangedSubview:slider];

    SetMuteLineView(self, stackView);
    UIView *content = [self contentView];
    if (content) {
        [content addSubview:stackView];
    }

    UpdateMuteViewForController(self);
}

- (void)userDidUpdate {
    %orig;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            UpdateMuteViewForController(strongSelf);
        }
    });
}

%end


// MARK: - NDCRTCChatActionHandler Hook

@interface NDCRTCChatActionHandler : NSObject
- (void)closeRTCChat;
@end

%hook NDCRTCChatActionHandler

- (void)closeRTCChat {
    %orig;
    if (usersVolume) {
        [usersVolume removeAllObjects];
    }
}

%end

#import <Foundation/Foundation.h>
#import <AVFAudio/AVFAudio.h>

// AVAudioApplication was introduced after iOS 16. Uber 4.584 references the
// class at launch. This compatibility class forwards recording permission to
// AVAudioSession, which provides the equivalent API on iOS 16. App-level input
// mute APIs have no direct iOS 16 equivalent, so they degrade to benign no-ops.

@interface AVAudioApplication : NSObject
+ (instancetype)sharedInstance;
+ (void)requestRecordPermissionWithCompletionHandler:(void (^)(BOOL granted))response;
+ (void)requestMicrophoneInjectionPermissionWithCompletionHandler:(void (^)(NSInteger permission))response;
- (NSUInteger)recordPermission;
- (NSInteger)microphoneInjectionPermission;
- (BOOL)isInputMuted;
- (BOOL)setInputMuted:(BOOL)muted error:(NSError **)outError;
- (BOOL)setInputMuteStateChangeHandler:(BOOL (^)(BOOL inputShouldBeMuted))handler error:(NSError **)outError;
@end

@implementation AVAudioApplication

+ (instancetype)sharedInstance {
    static AVAudioApplication *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [AVAudioApplication new];
    });
    return shared;
}

+ (void)requestRecordPermissionWithCompletionHandler:(void (^)(BOOL granted))response {
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (response) response(granted);
    }];
}

- (NSUInteger)recordPermission {
    return (NSUInteger)[AVAudioSession sharedInstance].recordPermission;
}

- (BOOL)isInputMuted {
    return NO;
}

- (BOOL)setInputMuted:(BOOL)muted error:(NSError **)outError {
    (void)muted;
    if (outError) *outError = nil;
    return YES;
}

- (BOOL)setInputMuteStateChangeHandler:(BOOL (^)(BOOL inputShouldBeMuted))handler error:(NSError **)outError {
    (void)handler;
    if (outError) *outError = nil;
    return YES;
}

+ (void)requestMicrophoneInjectionPermissionWithCompletionHandler:(void (^)(NSInteger permission))response {
    // Microphone injection is not available on iOS 16. Report unavailable.
    if (response) response(0);
}

- (NSInteger)microphoneInjectionPermission {
    return 0;
}

@end

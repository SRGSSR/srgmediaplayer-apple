//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIDevice+SRGMediaPlayer.h"

static BOOL s_locked = NO;

// Function declarations
static void lockComplete(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);

@implementation UIDevice (SRGMediaPlayer)

#pragma mark Class methods

+ (BOOL)srg_mediaPlayer_isLocked
{
    return s_locked;
}

#pragma mark Notifications

+ (void)srg_mediaPlayer_applicationDidBecomeActive:(NSNotification *)notification
{
    s_locked = NO;
}

@end

#pragma mark Functions

__attribute__((constructor)) static void SRGMediaPlayerUIDeviceInit(void)
{
    // Differentiate between device lock and application sent to the background
    // See http://stackoverflow.com/a/9058038/760435
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    (__bridge const void *)[UIDevice class],
                                    lockComplete,
                                    CFSTR("com.apple.springboard.lockcomplete"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    
    [[NSNotificationCenter defaultCenter] addObserver:[UIDevice class]
                                             selector:@selector(srg_mediaPlayer_applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

static void lockComplete(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    s_locked = YES;
}

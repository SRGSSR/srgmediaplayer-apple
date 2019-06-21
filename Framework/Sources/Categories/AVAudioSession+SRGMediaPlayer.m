//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AVAudioSession+SRGMediaPlayer.h"

#import "NSBundle+SRGMediaPlayer.h"

#import <MediaPlayer/MediaPlayer.h>

static MPVolumeView *s_volumeView = nil;

NSString * const SRGMediaPlayerWirelessRoutesAvailableDidChangeNotification = @"SRGMediaPlayerWirelessRoutesAvailableDidChangeNotification";
NSString * const SRGMediaPlayerWirelessRouteActiveDidChangeNotification = @"SRGMediaPlayerWirelessRouteActiveDidChangeNotification";

@implementation AVAudioSession (SRGMediaPlayer)

#pragma mark Class methods

+ (BOOL)srg_areWirelessRoutesAvailable
{
    return s_volumeView.areWirelessRoutesAvailable;
}

+ (BOOL)srg_isAirPlayActive
{
    AVAudioSession *audioSession = [self sharedInstance];
    AVAudioSessionRouteDescription *currentRoute = audioSession.currentRoute;
    
    for (AVAudioSessionPortDescription *outputPort in currentRoute.outputs) {
        if ([outputPort.portType isEqualToString:AVAudioSessionPortAirPlay]) {
            return YES;
        }
    }
    
    return NO;
}

+ (NSString *)srg_activeAirPlayRouteName
{
    AVAudioSession *audioSession = [self sharedInstance];
    AVAudioSessionRouteDescription *currentRoute = audioSession.currentRoute;
    
    for (AVAudioSessionPortDescription *outputPort in currentRoute.outputs) {
        if ([outputPort.portType isEqualToString:AVAudioSessionPortAirPlay]) {
            return outputPort.portName;
        }
    }
    
    if (currentRoute.outputs.count != 0) {
        return SRGMediaPlayerLocalizedString(@"an external device", @"AirPlay device description on which device the media is played if no name provided by the system. Use with \"This media is playing on %@\"");
    }
    else {
        return nil;
    }
}

#pragma mark Notifications

+ (void)srg_windowDidBecomeKey:(NSNotification *)notification
{
    // The volume view needs to be installed in a view hierarchy to correctly report routes (otherwise `-areWirelessRoutesAvailable`
    // always returns `NO`)
    s_volumeView = [[MPVolumeView alloc] init];
    s_volumeView.hidden = YES;
    
    UIWindow *window = notification.object;
    [window insertSubview:s_volumeView atIndex:0];
}

+ (void)srg_wirelessRouteAvailableDidChange:(NSNotification *)notification
{
    [NSNotificationCenter.defaultCenter postNotificationName:SRGMediaPlayerWirelessRoutesAvailableDidChangeNotification object:nil];
}

+ (void)srg_wirelessRouteActiveDidChange:(NSNotification *)notification
{
    [NSNotificationCenter.defaultCenter postNotificationName:SRGMediaPlayerWirelessRouteActiveDidChangeNotification object:nil];
}

@end

__attribute__((constructor)) static void AVAudioSessionInit(void)
{
    [NSNotificationCenter.defaultCenter addObserver:AVAudioSession.class
                                           selector:@selector(srg_windowDidBecomeKey:)
                                               name:UIWindowDidBecomeKeyNotification
                                             object:nil];
}

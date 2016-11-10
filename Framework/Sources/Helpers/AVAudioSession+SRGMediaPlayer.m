//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AVAudioSession+SRGMediaPlayer.h"

#import "NSBundle+SRGMediaPlayer.h"

#import <MediaPlayer/MediaPlayer.h>

static MPVolumeView *s_volumeView = nil;

NSString * const SRGMediaPlayerWirelessRouteDidChangeNotification = @"SRGMediaPlayerWirelessRouteDidChangeNotification";

@implementation AVAudioSession (SRGMediaPlayer)

#pragma mark Class methods

+ (BOOL)srg_isAirplayActive
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

+ (NSString *)srg_activeAirplayRouteName
{
    AVAudioSession *audioSession = [self sharedInstance];
    AVAudioSessionRouteDescription *currentRoute = audioSession.currentRoute;
    
    for (AVAudioSessionPortDescription *outputPort in currentRoute.outputs) {
        if ([outputPort.portType isEqualToString:AVAudioSessionPortAirPlay]) {
            return outputPort.portName;
        }
    }
    
    return SRGMediaPlayerLocalizedString(@"External device", nil);
}

#pragma mark Notifications

+ (void)srg_wirelessRouteActiveDidChange:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SRGMediaPlayerWirelessRouteDidChangeNotification object:nil];
}

@end

__attribute__((constructor)) static void AVAudioSessionInit(void)
{
    s_volumeView = [[MPVolumeView alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:[AVAudioSession class]
                                             selector:@selector(srg_wirelessRouteActiveDidChange:)
                                                 name:MPVolumeViewWirelessRouteActiveDidChangeNotification
                                               object:s_volumeView];
}


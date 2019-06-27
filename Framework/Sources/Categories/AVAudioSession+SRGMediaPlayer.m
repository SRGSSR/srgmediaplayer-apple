//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AVAudioSession+SRGMediaPlayer.h"

#import "NSBundle+SRGMediaPlayer.h"

@implementation AVAudioSession (SRGMediaPlayer)

#pragma mark Class methods

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


@end


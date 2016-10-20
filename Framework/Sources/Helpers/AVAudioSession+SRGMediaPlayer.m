//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AVAudioSession+SRGMediaPlayer.h"

@implementation AVAudioSession (SRGMediaPlayer)

#pragma mark Class methods

+ (BOOL)srg_isAirplayActive
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    AVAudioSessionRouteDescription *currentRoute = audioSession.currentRoute;
    
    for (AVAudioSessionPortDescription *outputPort in currentRoute.outputs) {
        if ([outputPort.portType isEqualToString:AVAudioSessionPortAirPlay]) {
            return YES;
        }
    }
    
    return NO;
}

@end

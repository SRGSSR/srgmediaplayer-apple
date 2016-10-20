//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <AVFoundation/AVFoundation.h>

@interface AVAudioSession (SRGMediaPlayer)

/**
 *  Returns YES iff Airplay is active (i.e. displaying on an external Airplay device)
 */
+ (BOOL)srg_isAirplayActive;

@end

//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIScreen+SRGMediaPlayer.h"

@implementation UIScreen (SRGMediaPlayer)

#pragma mark Class methods

+ (BOOL)srg_isMirroring
{
    for (UIScreen *screen in [self screens]) {
        if (screen.mirroredScreen) {
            return YES;
        }
    }
    
    return NO;
}

@end

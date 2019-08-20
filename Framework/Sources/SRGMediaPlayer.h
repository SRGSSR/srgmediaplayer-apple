//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

// Oficial version number.
FOUNDATION_EXPORT NSString *SRGMediaPlayerMarketingVersion(void);

// Public headers.
#import "CMTime+SRGMediaPlayer.h"
#import "CMTimeRange+SRGMediaPlayer.h"
#import "SRGActivityGestureRecognizer.h"
#import "SRGMediaPlayerConstants.h"
#import "SRGMediaPlayerController.h"
#import "SRGMediaPlayerError.h"
#import "SRGMediaPlayerView.h"
#import "SRGNativeMediaPlayerViewController.h"
#import "SRGPlaybackActivityIndicatorView.h"
#import "SRGSegment.h"
#import "SRGPosition.h"
#import "SRGTimelineView.h"
#import "SRGViewModeButton.h"
#import "UIScreen+SRGMediaPlayer.h"

#if TARGET_OS_IOS

#import "AVAudioSession+SRGMediaPlayer.h"
#import "SRGAirPlayButton.h"
#import "SRGAirPlayView.h"
#import "SRGPictureInPictureButton.h"
#import "SRGPlaybackButton.h"
#import "SRGTimeSlider.h"
#import "SRGTimelineSlider.h"
#import "SRGTracksButton.h"
#import "SRGVolumeView.h"

#endif

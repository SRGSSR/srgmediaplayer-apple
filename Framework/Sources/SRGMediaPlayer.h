//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

// Oficial version number.
FOUNDATION_EXPORT NSString *SRGMediaPlayerMarketingVersion(void);

// Public headers.
#import "AVAudioSession+SRGMediaPlayer.h"
#import "CMTime+SRGMediaPlayer.h"
#import "CMTimeRange+SRGMediaPlayer.h"
#import "SRGMediaPlayerConstants.h"
#import "SRGMediaPlayerController.h"
#import "SRGMediaPlayerError.h"
#import "SRGMediaPlayerView.h"
#import "SRGMediaPlayerViewController.h"
#import "SRGPlaybackActivityIndicatorView.h"
#import "SRGPosition.h"
#import "SRGSegment.h"
#import "UIScreen+SRGMediaPlayer.h"

#if TARGET_OS_IOS

#import "SRGActivityGestureRecognizer.h"
#import "SRGAirPlayButton.h"
#import "SRGAirPlayView.h"
#import "SRGPictureInPictureButton.h"
#import "SRGPlaybackButton.h"
#import "SRGTimelineSlider.h"
#import "SRGTimelineView.h"
#import "SRGTimeSlider.h"
#import "SRGTracksButton.h"
#import "SRGViewModeButton.h"
#import "SRGVolumeView.h"

#endif

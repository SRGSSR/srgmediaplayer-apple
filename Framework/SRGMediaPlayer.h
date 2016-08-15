//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

//! Project version number for SRGMediaPlayer.
FOUNDATION_EXPORT double SRGMediaPlayerVersionNumber;

//! Project version string for SRGMediaPlayer.
FOUNDATION_EXPORT const unsigned char SRGMediaPlayerVersionString[];

#import "RTSMediaPlayerConstants.h"
#import "RTSMediaPlayerController.h"
#import "RTSMediaPlayerControllerDataSource.h"
#import "RTSMediaPlayerError.h"
#import "RTSMediaPlayerViewController.h"

// Overlay Views
#import "RTSMediaPlayerPlaybackButton.h"
#import "RTSAirplayOverlayView.h"
#import "RTSMediaFailureOverlayView.h"
#import "RTSPictureInPictureButton.h"
#import "RTSTimeSlider.h"
#import "RTSVolumeView.h"
#import "RTSPlaybackActivityIndicatorView.h"

// Segments
#import "RTSMediaSegment.h"
#import "RTSMediaSegmentsController.h"
#import "RTSMediaSegmentsDataSource.h"

// Overlay Views for Segments
#import "RTSTimelineSlider.h"
#import "RTSSegmentedTimelineView.h"

// Utils
#import "NSBundle+RTSMediaPlayer.h"
#import "RTSActivityGestureRecognizer.h"

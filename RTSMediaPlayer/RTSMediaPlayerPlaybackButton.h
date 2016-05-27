//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

/**
 *  Behaviors supported by the playback button
 */
typedef NS_ENUM(NSInteger, RTSMediaPlayerPlaybackButtonBehavior) {
	/**
	 *  Default behavior (play / pause)
	 */
	RTSMediaPlayerPlaybackButtonBehaviorDefault,
	/**
	 *  Play / pause only for on-demand and DVR streams. Play / stop for live streams
	 */
	RTSMediaPlayerPlaybackButtonBehaviorStopForLiveOnly,
	/**
	 *  Play / stop only for all kinds of streams
	 */
	RTSMediaPlayerPlaybackButtonBehaviorStopForAll
};

// Forward declarations
@class RTSMediaPlayerController;

/**
 *  A play / pause button whose status is automatically synchronized with the media player controller it is attached
 *  to
 *
 *  Simply install an instance somewhere onto your custom player interface and bind to the media player controller which 
 *  needs to be controlled
 */
@interface RTSMediaPlayerPlaybackButton : UIButton

/**
 *  The media player to which the playback button must be associated with.
 */
@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;

/**
 *  Color customization
 */
@property (nonatomic) IBInspectable UIColor *normalColor;
@property (nonatomic) IBInspectable UIColor *hightlightColor;

/**
 * Image customization (default images are used if not set)
 */
@property (nonatomic) UIImage *playImage;
@property (nonatomic) UIImage *pauseImage;
@property (nonatomic) UIImage *stopImage;

/**
 *  Button behavior. Default is RTSMediaPlayerPlaybackButtonBehaviorDefault
 */
@property (nonatomic) RTSMediaPlayerPlaybackButtonBehavior behavior;

@end

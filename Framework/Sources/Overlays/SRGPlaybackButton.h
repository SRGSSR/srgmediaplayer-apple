//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Behaviors supported by the playback button
 */
typedef NS_ENUM(NSInteger, SRGPlaybackButtonBehavior) {
    /**
     *  Default behavior (play / pause)
     */
    SRGPlaybackButtonBehaviorDefault,
    /**
     *  Play / pause only for on-demand and DVR streams. Play / stop for live streams
     */
    SRGPlaybackButtonBehaviorStopForLiveOnly,
    /**
     *  Play / stop only for all kinds of streams
     */
    SRGPlaybackButtonBehaviorStopForAll
};

/**
 *  A play / pause button whose status is automatically synchronized with the media player controller it is attached
 *  to
 *
 *  Simply install an instance somewhere onto your custom player interface and bind to the media player controller which
 *  needs to be controlled
 */
@interface SRGPlaybackButton : UIButton

/**
 *  The media player to which the playback button must be associated with.
 */
@property (nonatomic, weak, nullable) IBOutlet SRGMediaPlayerController *mediaPlayerController;

/**
 *  Image customization (default images are used if not set)
 */
@property (nonatomic, null_resettable) IBInspectable UIImage *playImage;
@property (nonatomic, null_resettable) IBInspectable UIImage *pauseImage;
@property (nonatomic, null_resettable) IBInspectable UIImage *stopImage;

/**
 *  The tint color to apply when the button is highlighted (if nil, then the usual tint color is applied)
 */
@property (nonatomic, null_resettable) IBInspectable UIColor *highlightedTintColor;

/**
 *  Set the button behavior for some stream type (default is NO for all stream types). If stop is set to NO for some
 *  stream type, a stop button will be displayed instead of the pause button when a stream of this type is played
 *
 *  @discussion Attempting to set this value for `SRGMediaPlayerStreamType` has no effect
 */
- (void)setStopping:(BOOL)stopping forStreamType:(SRGMediaPlayerStreamType)streamType;

@end

NS_ASSUME_NONNULL_END

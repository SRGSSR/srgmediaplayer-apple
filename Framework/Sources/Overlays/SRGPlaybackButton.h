//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Possible button states.
 */
typedef NS_ENUM(NSInteger, SRGPlaybackButtonState) {
    SRGPlaybackButtonStatePlay,
    SRGPlaybackButtonStatePause
};

/**
 *  A play / pause button whose status is automatically synchronized with the media player controller it is attached
 *  to.
 *
 *  Simply install an instance somewhere onto your custom player interface and bind to the media player controller which
 *  needs to be controlled.
 *
 *  Remark: This special kind of button does not support the display of a title.
 */
API_UNAVAILABLE(tvos)
@interface SRGPlaybackButton : UIButton

/**
 *  The media player which the playback button must be associated with.
 */
@property (nonatomic, weak, nullable) IBOutlet SRGMediaPlayerController *mediaPlayerController;

/**
 *  The current button state.
 */
@property (nonatomic, readonly) SRGPlaybackButtonState playbackButtonState;

/**
 *  Image customization (a default image is used if not set).
 */
@property (nonatomic, null_resettable) UIImage *playImage;
@property (nonatomic, null_resettable) UIImage *pauseImage;

/**
 *  The tint color to apply when the button is highlighted (if nil, then the tint color is applied).
 */
@property (nonatomic, null_resettable) IBInspectable UIColor *highlightedTintColor;

/**
 *  The action to be executed when the button is tapped. If not set, the default behavior is applied (the
 *  `-togglePlayPause` method is called on the associated controller, otherwise the defined action replaces
 *  the default behavior.
 */
@property (nonatomic, copy, nullable) void (^action)(void);

@end

NS_ASSUME_NONNULL_END

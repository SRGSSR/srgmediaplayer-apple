//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class SRGPlaybackButton;

/**
 *  Possible button states.
 */
typedef NS_ENUM(NSInteger, SRGPlaybackButtonState) {
    SRGPlaybackButtonStatePlay,         // The button is in a state where pressing it should trigger a play (displays a play icon by default).
    SRGPlaybackButtonStatePause         // The button is in a state where pressing it should trigger a pause (displays a pause icon by default).
};

/**
 *  Playack button delegate protocol for customization.
 */
API_UNAVAILABLE(tvos)
@protocol SRGPlaybackButtonDelegate <NSObject>

@optional

/**
 *  If implementd, replaces the default action bound to the button (a call to `-togglePlayPause` for the associated
 *  controller). The current state the button is in is provided as parameter.
 */
- (void)playbackButton:(SRGPlaybackButton *)playbackButton didPressInState:(SRGPlaybackButtonState)state;

/**
 *  If implemented, must return the accessibility labels to be used for the provided state. If not implemented,
 *  default labels are used instead.
 */
- (NSString *)playbackButton:(SRGPlaybackButton *)playbackButton accessibilityLabelForState:(SRGPlaybackButtonState)state;

@end

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
 *  The button customization delegate.
 */
@property (nonatomic, weak) id<SRGPlaybackButtonDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

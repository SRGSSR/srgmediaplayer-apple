//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController.h"
#import "SRGMediaPlayerConstants.h"

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@class SRGSettingsButton;

/**
 *  Settings button delegate protocol.
 */
API_UNAVAILABLE(tvos)
@protocol SRGSettingsButtonDelegate <NSObject>

@optional

/**
 *  The button is about to show the settings view.
 */
- (void)settingsButtonWillShowSettings:(SRGSettingsButton *)settingsButton;

/**
 *  The settings have been hidden.
 */
- (void)settingsButtonDidHideSettings:(SRGSettingsButton *)settingsButton;

@end

/**
 *  Button which provides access to the player settings (playback speeds, audio tracks and subtitles). If your controls
 *  are stacked using a `UIStackView`, the layout will automatically adjust when the button appears or disappears.
 */
API_UNAVAILABLE(tvos)
@interface SRGSettingsButton : UIView

/**
 *  The media player which the button must be associated with.
 */
@property (nonatomic, weak, nullable) IBOutlet SRGMediaPlayerController *mediaPlayerController;

/**
 *  Image customization (a default image is used if not set).
 */
@property (nonatomic, null_resettable) UIImage *image;

/**
 *  The style to be applied to the settings popover. Default value is `SRGMediaPlayerUserInterfaceStyleUnspecified`
 *  (default dark appearance prior to iOS 13, and based on dark mode settings for iOS 13 and above).
 *
 *  @discussion The style will be applied the next time the popover is opened.
 */
@property (nonatomic) SRGMediaPlayerUserInterfaceStyle userInterfaceStyle;

/**
 *  The button delegate.
 */
@property (nonatomic, weak) IBOutlet id<SRGSettingsButtonDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

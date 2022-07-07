//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController.h"
#import "SRGMediaPlayerConstants.h"

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@class SRGPlaybackSettingsButton;

/**
 *  Playback settings button delegate protocol.
 */
API_UNAVAILABLE(tvos)
@protocol SRGPlaybackSettingsButtonDelegate <NSObject>

@optional

/**
 *  Called when the user changed the playback speed.
 */
- (void)playbackSettingsButton:(SRGPlaybackSettingsButton *)playbackSettingsButton didSelectPlaybackRate:(float)playbackRate;

/**
 *  Called when the user changed the audio language (`nil` if the default application language is selected).
 */
- (void)playbackSettingsButton:(SRGPlaybackSettingsButton *)playbackSettingsButton didSelectAudioLanguageCode:(nullable NSString *)languageCode;

/**
 *  Called when the user changed the subtitle language (`nil` if none or automatic).
 */
- (void)playbackSettingsButton:(SRGPlaybackSettingsButton *)playbackSettingsButton didSelectSubtitleLanguageCode:(nullable NSString *)languageCode;

/**
 *  Called when the button is about to show the playback settings view.
 */
- (void)playbackSettingsButtonWillShowSettings:(SRGPlaybackSettingsButton *)playbackSettingsButton;

/**
 *  Called when the playback settings have been hidden.
 */
- (void)playbackSettingsButtonDidHideSettings:(SRGPlaybackSettingsButton *)playbackSettingsButton;

@end

/**
 *  Button which provides access to the playback settings (playback speeds, audio tracks and subtitles). If your controls
 *  are stacked using a `UIStackView`, the layout will automatically adjust when the button appears or disappears.
 */
API_UNAVAILABLE(tvos)
@interface SRGPlaybackSettingsButton : UIView

/**
 *  The media player which the button must be associated with.
 */
@property (nonatomic, weak, nullable) IBOutlet SRGMediaPlayerController *mediaPlayerController;

/**
 *  Image customization (a default image is used if not set).
 */
@property (nonatomic, null_resettable) UIImage *image;

/**
 *  The style to be applied to the settings popover. Default value is `UIUserInterfaceStyleUnspecified`
 *  (default dark appearance prior to iOS 13, and based on dark mode settings for iOS 13 and above).
 *
 *  @discussion The style will be applied the next time the popover is opened.
 */
@property (nonatomic) UIUserInterfaceStyle userInterfaceStyle;

/**
 *  The button delegate.
 */
@property (nonatomic, weak, nullable) IBOutlet id<SRGPlaybackSettingsButtonDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

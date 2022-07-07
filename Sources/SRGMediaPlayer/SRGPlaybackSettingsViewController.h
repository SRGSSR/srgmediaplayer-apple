//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController.h"
#import "SRGMediaPlayerConstants.h"

@import AVFoundation;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class SRGPlaybackSettingsViewController;

/**
 *  Playback settings view controller delegate protocol.
 */
@protocol SRGPlaybackSettingsViewControllerDelegate <NSObject>

/**
 *  Called when the user changed the playback speed.
 */
- (void)playbackSettingsViewController:(SRGPlaybackSettingsViewController *)settingsViewController didSelectPlaybackRate:(float)playbackRate;

/**
 *  Called when the user changed the audio language (`nil` if the default application language is selected).
 */
- (void)playbackSettingsViewController:(SRGPlaybackSettingsViewController *)settingsViewController didSelectAudioLanguageCode:(nullable NSString *)languageCode;

/**
 *  Called when the user changed the subtitle language (`nil` if none or automatic).
 */
- (void)playbackSettingsViewController:(SRGPlaybackSettingsViewController *)settingsViewController didSelectSubtitleLanguageCode:(nullable NSString *)languageCode;

/**
 *  Called after the view controller has been dismissed.
 */
- (void)playbackSettingsViewControllerWasDismissed:(SRGPlaybackSettingsViewController *)settingsViewController;

@end

/**
 *  View controller displaying playback settings. For internal use.
 */
API_UNAVAILABLE(tvos)
@interface SRGPlaybackSettingsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

/**
 *  Create an instance displaying settings for a controller and adjusted for the provided style.
 */
- (instancetype)initWithMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController userInterfaceStyle:(UIUserInterfaceStyle)userInterfaceStyle;

/**
 *  The view controller delegate.
 */
@property (nonatomic, weak, nullable) id<SRGPlaybackSettingsViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

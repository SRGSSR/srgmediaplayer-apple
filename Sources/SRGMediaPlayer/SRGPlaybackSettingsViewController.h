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
- (instancetype)initWithMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController userInterfaceStyle:(SRGMediaPlayerUserInterfaceStyle)userInterfaceStyle;

/**
 *  The view controller delegate.
 */
@property (nonatomic, weak, nullable) id<SRGPlaybackSettingsViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

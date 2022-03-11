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
@class SRGSettingsViewController;

/**
 *  Tracks view controller delegate protocol.
 */
@protocol SRGSettingsViewControllerDelegate <NSObject>

/**
 *  Called after the view controller has been dismissed.
 */
- (void)settingsViewControllerWasDismissed:(SRGSettingsViewController *)settingsViewController;

@end

/**
 *  View controller displaying subtitles and audio tracks. For internal use.
 */
API_UNAVAILABLE(tvos)
@interface SRGSettingsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

/**
 *  Create an instance displaying tracks for a controller and adjusted for the provided style.
 */
- (instancetype)initWithMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController userInterfaceStyle:(SRGMediaPlayerUserInterfaceStyle)userInterfaceStyle;

/**
 *
 */
@property (nonatomic, weak) id<SRGSettingsViewControllerDelegate> delegate;

@end


NS_ASSUME_NONNULL_END

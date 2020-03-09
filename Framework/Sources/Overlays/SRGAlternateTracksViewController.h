//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController.h"
#import "SRGMediaPlayerConstants.h"

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class SRGAlternateTracksViewController;

/**
 *  Tracks view controller delegate protocol.
 */
@protocol SRGAlternateTracksViewControllerDelegate <NSObject>

/**
 *  Called after the view controller has been dismissed.
 */
- (void)alternateTracksViewControllerWasDismissed:(SRGAlternateTracksViewController *)alternateTracksViewController;

@end

/**
 *  View controller displaying subtitles and audio tracks. For internal use.
 */
API_UNAVAILABLE(tvos)
@interface SRGAlternateTracksViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

/**
 *  Create an instance displaying tracks for a controller and adjusted for the provided style.
 */
- (instancetype)initWithMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController userInterfaceStyle:(SRGMediaPlayerUserInterfaceStyle)userInterfaceStyle;

/**
 *
 */
@property (nonatomic, weak) id<SRGAlternateTracksViewControllerDelegate> delegate;

@end


NS_ASSUME_NONNULL_END

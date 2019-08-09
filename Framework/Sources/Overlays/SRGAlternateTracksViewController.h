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

@class SRGAlternateTracksViewController;

/**
 *  Alternate tracks view controller delegate protocol.
 */
@protocol SRGAlternateTracksViewControllerDelegate <NSObject>

/**
 *  The view did disappear.
 */
- (void)alternateTracksViewController:(SRGAlternateTracksViewController *)alternateTracksViewController viewDidDisappear:(BOOL)animated;

@end

/**
 *  View controller displaying subtitles and audio tracks. For internal use.
 */
@interface SRGAlternateTracksViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

/**
 *  Return an instance wrapped into a navigation controller.
 */
+ (UINavigationController *)alternateTracksNavigationControllerForMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
                                                                 withUserInterfaceStyle:(SRGMediaPlayerUserInterfaceStyle)userInterfaceStyle
                                                                               delegate:(nullable id<SRGAlternateTracksViewControllerDelegate>)delegate;
@end


NS_ASSUME_NONNULL_END

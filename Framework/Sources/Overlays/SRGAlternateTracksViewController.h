//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController.h"

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SRGAlternateTracksViewController;

/**
 *  Delegate protocol for `SRGAlternateTracksViewController`.
 */
@protocol SRGAlternateTracksViewControllerDelegate <NSObject>

@optional

/**
 *  Called when a media option has been selected (subtitles or audio tracks).
 */
- (void)alternateTracksViewControllerDidSelectMediaOption:(SRGAlternateTracksViewController *)alternateTracksViewController;

@end

/**
 *  View controller displaying subtitles and audio tracks. For internal use.
 */
@interface SRGAlternateTracksViewController : UITableViewController

/**
 *  Return an instance wrapped into a navigation controller.
 */
+ (UINavigationController *)alternateTracksNavigationControllerForMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController withDelegate:(nullable id<SRGAlternateTracksViewControllerDelegate>)delegate;

/**
 *  The view controller delegate.
 */
@property (nonatomic, readonly, weak) id<SRGAlternateTracksViewControllerDelegate> delegate;

@end


NS_ASSUME_NONNULL_END

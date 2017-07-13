//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

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
 *  Called when a media option has been selected within a group (subtitles or audio tracks).
 */
- (void)alternateTracksViewController:(SRGAlternateTracksViewController *)alternateTracksViewController didSelectMediaOption:(nullable AVMediaSelectionOption *)option inGroup:(AVMediaSelectionGroup *)group;

@end

/**
 *  View controller displaying subtitles and audio tracks. For internal use.
 */
@interface SRGAlternateTracksViewController : UITableViewController

/**
 *  Return an instance wrapped into a navigation controller.
 */
+ (UINavigationController *)alternateTracksNavigationControllerForPlayer:(AVPlayer *)player
                                                            withDelegate:(nullable id<SRGAlternateTracksViewControllerDelegate>)delegate;

/**
 *  The view controller delegate.
 */
@property (weak) id<SRGAlternateTracksViewControllerDelegate> delegate;

@end


NS_ASSUME_NONNULL_END

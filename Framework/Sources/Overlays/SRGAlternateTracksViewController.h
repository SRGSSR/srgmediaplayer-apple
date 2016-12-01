//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SRGAlternateTracksViewController;

@protocol SRGAlternateTracksViewControllerDelegate <NSObject>

@optional
- (void)alternateTracksViewController:(SRGAlternateTracksViewController *)alternateTracksViewController selectedMediaOption:(AVMediaSelectionOption *)option inGroup:(AVMediaSelectionGroup *)group;

@end

@interface SRGAlternateTracksViewController : UITableViewController

@property (assign) id<SRGAlternateTracksViewControllerDelegate> delegate;

+ (UIPopoverController *)alternateTracksViewControllerInPopoverForPlayer:(AVPlayer *)player
                                                                delegate:(nullable id<SRGAlternateTracksViewControllerDelegate>)delegate;

+ (UINavigationController *)alternateTracksViewControllerInNavigationControllerForPlayer:(AVPlayer *)player
                                                                                delegate:(nullable id<SRGAlternateTracksViewControllerDelegate>)delegate;

@end


NS_ASSUME_NONNULL_END

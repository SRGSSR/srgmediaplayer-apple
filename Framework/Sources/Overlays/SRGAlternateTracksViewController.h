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

+ (UIPopoverController *)alternateTracksViewControllerInPopoverWithDelegate:(nullable id<SRGAlternateTracksViewControllerDelegate>)delegate
                                                                     player:(AVPlayer *)player;

+ (UINavigationController *)alternateTracksViewControllerInNavigationControllerWithDelegate:(nullable id<SRGAlternateTracksViewControllerDelegate>)delegate
                                                                                     player:(AVPlayer *)player;
@end


NS_ASSUME_NONNULL_END

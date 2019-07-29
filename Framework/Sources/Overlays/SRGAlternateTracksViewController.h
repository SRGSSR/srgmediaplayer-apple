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

/**
 *  View controller displaying subtitles and audio tracks. For internal use.
 */
@interface SRGAlternateTracksViewController : UITableViewController

/**
 *  Return an instance wrapped into a navigation controller.
 */
+ (UINavigationController *)alternateTracksNavigationControllerForMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
                                                                 withUserInterfaceStyle:(SRGMediaPlayerUserInterfaceStyle)userInterfaceStyle;

@end


NS_ASSUME_NONNULL_END

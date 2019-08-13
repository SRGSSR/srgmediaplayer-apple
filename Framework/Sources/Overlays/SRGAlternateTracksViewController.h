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
@interface SRGAlternateTracksViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

/**
 *  Create an instance displaying tracks for a controller and adjusted for the provided style.
 */
- (instancetype)initWithMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController userInterfaceStyle:(SRGMediaPlayerUserInterfaceStyle)userInterfaceStyle;

@end


NS_ASSUME_NONNULL_END

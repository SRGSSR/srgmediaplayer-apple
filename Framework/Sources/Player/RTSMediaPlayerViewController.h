//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

/**
 *  `RTSMediaPlayerViewController` is inspired by the `MPMoviePlayerViewController` class, and intends to provide a full-screen
 *  standard media player looking like the default iOS media player.
 *
 *  The RTSMediaPlayerViewController has to be presented modally using `-presentViewController:animated:completion:`. If you
 *  need a customized layout, create your own view controller and implement media playback using `RTSMediaPlayerController`
 */
@interface RTSMediaPlayerViewController : UIViewController

/**
 *  Returns an `RTSMediaPlayerViewController` object initialized with the media at the specified URL
 */
- (instancetype) initWithContentURL:(NSURL *)contentURL NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) NSURL *contentURL;

@end

//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  `SRGMediaPlayerViewController` is inspired by the `MPMoviePlayerViewController` class, and intends to provide a full-screen
 *  standard media player looking like the default iOS media player.
 *
 *  An `SRGMediaPlayerViewController` instance has to be presented modally using `-presentViewController:animated:completion:`. 
 *  If you need a custom layout, create your own view controller and implement media playback using `SRGMediaPlayerController`
 *  instead.
 */
@interface SRGMediaPlayerViewController : UIViewController <UIGestureRecognizerDelegate>

/**
 *  Returns an `SRGMediaPlayerViewController` object initialized with the media at the specified URL
 */
- (instancetype)initWithContentURL:(NSURL *)contentURL NS_DESIGNATED_INITIALIZER;

/**
 *  The URL of the content being played
 */
@property (nonatomic, readonly) NSURL *contentURL;

@end

NS_ASSUME_NONNULL_END

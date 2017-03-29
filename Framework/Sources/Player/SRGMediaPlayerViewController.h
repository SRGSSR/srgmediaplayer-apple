//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  `SRGMediaPlayerViewController` is inspired by the `AVPlayerViewController` class, and intends to provide a full-screen
 *  standard media player looking like the default iOS media player.
 *
 *  An `SRGMediaPlayerViewController` instance has to be presented modally using `-presentViewController:animated:completion:`. 
 *  If you need a custom layout, create your own view controller and implement media playback using `SRGMediaPlayerController`
 *  instead.
 *
 *  Like `AVPlayerViewController`, `SRGMediaPlayerViewController` exposes the underlying controller for usual playback
 *  operations. After instantiating the view controller, you must therefore start playback by calling one of the `-play...`
 *  methods available.
 */
@interface SRGMediaPlayerViewController : UIViewController <UIGestureRecognizerDelegate>

/**
 *  The underlying controller. Use for starting or pausing playback or listening to playback notifications, for example 
 */
@property (nonatomic, readonly) SRGMediaPlayerController *controller;

@end

@interface SRGMediaPlayerViewController (Unavailable)

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

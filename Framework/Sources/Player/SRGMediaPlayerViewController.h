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
 *  @param URL               The URL to play
 *
 *  @param userInfo          An optional dictionary to associate arbitrary information with the media being played (for later retrieval).
 *                           This information stays associated with the inside player controller
 *
 *  Returns an `SRGMediaPlayerViewController` object initialized with the media at the specified URL and an optional user info dictionnary
 */
- (instancetype)initWithContentURL:(NSURL *)contentURL userInfo:(nullable NSDictionary *)userInfo NS_DESIGNATED_INITIALIZER;

/**
 *  The URL of the content being played
 */
@property (nonatomic, readonly) NSURL *contentURL;

/**
 *  The optional dictionnary associated to the content
 */
@property (nonatomic, readonly, nullable) NSDictionary *userInfo;

@end

@interface SRGMediaPlayerViewController (Unavailable)

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

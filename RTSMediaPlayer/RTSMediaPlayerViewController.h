//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>
#import <SRGMediaPlayer/RTSMediaPlayerControllerDataSource.h>

/**
 *  RTSMediaPlayerViewController is inspired by the MPMoviePlayerViewController class.
 *  The RTSMediaPlayerViewController class implements a simple view controller for displaying full-screen movies. It mimics the default 
 *  iOS Movie player based on MPMoviePlayerViewController.
 *
 *  The RTSMediaPlayerViewController has to be presented modally using `-presentViewController:animated:completion:`
 */
@interface RTSMediaPlayerViewController : UIViewController

/**
 *  Returns a RTSMediaPlayerViewController object initialized with the media at the specified URL which mimics the standard 
 *  MPMoviePlayerViewController style.
 *
 *  @param contentURL The URL of the media to be played
 *
 *  @return A media player view controller
 */
- (instancetype) initWithContentURL:(NSURL *)contentURL OS_NONNULL_ALL;

/**
 *  Returns a RTSMediaPlayerController object initialized with a datasource and a media identifier which mimics the standard
 *  MPMoviePlayerViewController style.
 *
 *  @param identifier The identifier of the media to be played
 *  @param dataSource The data source from which the media URL will be retrieved
 *
 *  @return A media player view controller
 */
- (instancetype) initWithContentIdentifier:(NSString *)identifier dataSource:(id<RTSMediaPlayerControllerDataSource>)dataSource OS_NONNULL_ALL;

@end

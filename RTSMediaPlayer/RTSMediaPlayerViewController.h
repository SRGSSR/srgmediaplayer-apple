//
//  Created by Frédéric Humbert-Droz on 03/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RTSMediaPlayer/RTSMediaPlayerControllerDataSource.h>

/**
 *  RTSMediaPlayerViewController is inspired by the MPMoviePlayerViewController class.
 *  The RTSMediaPlayerViewController class implements a simple view controller for displaying full-screen movies. It mimics the default iOS Movie player based on MPMoviePlayerViewController.
 *
 *  The RTSMediaPlayerViewController has to be presented modally using `-presentViewController:animated:completion:`
 */
@interface RTSMediaPlayerViewController : UIViewController

/**
 *  Returns a RTSMediaPlayerViewController object initialized with the media at the specified URL which mimics the standard MPMoviePlayerViewController style.
 *
 *  @param contentURL <#contentURL description#>
 *
 *  @return A media player view controller
 */
- (instancetype) initWithContentURL:(NSURL *)contentURL OS_NONNULL_ALL;

/**
 *  Returns a RTSMediaPlayerController object initialized with a datasource and a media identifier which mimics the standard MPMoviePlayerViewController style.
 *
 *  @param identifier <#identifier description#>
 *  @param dataSource <#dataSource description#>
 *
 *  @return A media player view controller
 */
- (instancetype) initWithContentIdentifier:(NSString *)identifier dataSource:(id<RTSMediaPlayerControllerDataSource>)dataSource NS_DESIGNATED_INITIALIZER OS_NONNULL_ALL;


@end

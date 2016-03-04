//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

@protocol RTSMediaPlayerControllerDataSource;

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
- (instancetype) initWithContentURL:(NSURL *)contentURL OS_NONNULL_ALL;

/**
 *  Returns a RTSMediaPlayerController object initialized with a datasource and a media identifier. The media URL will be
 *  retrieved from the data source based on its identifier
 *
 *  @param identifier The identifier of the media to be played
 *  @param dataSource The data source from which the media URL will be retrieved
 */
- (instancetype) initWithContentIdentifier:(NSString *)identifier dataSource:(id<RTSMediaPlayerControllerDataSource>)dataSource OS_NONNULL_ALL;

@end

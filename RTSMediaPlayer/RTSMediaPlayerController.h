//
//  Created by Cédric Luthi on 25.02.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <RTSMediaPlayer/RTSMediaPlayerControllerDataSource.h>

/**
 *  - Like MPMoviePlayerController
 *  - Notification based, @see notifications
 *  - State
 *  - Error, also handles the error from the dataSource
 */
@interface RTSMediaPlayerController : NSObject

/**
 *  --------------------------------------------
 *  @name Initializing a Media Player Controller
 *  --------------------------------------------
 */

/**
*  <#Description#>
*
*  @param contentURL <#contentURL description#>
*
*  @return A media player controller
*/
- (instancetype) initWithContentURL:(NSURL *)contentURL OS_NONNULL_ALL;

/**
 *  <#Description#>
 *
 *  @param identifier <#identifier description#>
 *  @param dataSource <#dataSource description#>
 *
 *  @return <#return value description#>
 */
- (instancetype) initWithContentIdentifier:(NSString *)identifier dataSource:(id<RTSMediaPlayerControllerDataSource>)dataSource NS_DESIGNATED_INITIALIZER OS_NONNULL_ALL;

/**
 *  --------------------------------
 *  @name Accessing Media Properties
 *  --------------------------------
 */

/**
 *  <#Description#>
 */
@property (readonly) id<RTSMediaPlayerControllerDataSource> dataSource;

/**
 *  <#Description#>
 */
@property (readonly) NSString *identifier;

/**
 *  ----------------------
 *  @name Playback Control
 *  ----------------------
 */

- (void) play;
- (void) playIdentifier:(NSString *)identifier;
- (void) pause;
- (void) seekToTime:(NSTimeInterval)time;

@end

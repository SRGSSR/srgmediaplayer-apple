//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

// Forward declarations
@class RTSMediaPlayerController;

/**
 *  An activity indicator displaying the current status of the associated media player controller.
 *
 *  Simply install an instance somewhere onto your custom player interface and bind to a media player
 *  controller.
 *
 *  Besides setting the mediaPlayerController outlet and appearance properties (color, size, alpha), 
 *  you should never:
 *    - call `startAnimating` or `stopAnimating`
 *    - change the values of the hidden or `hidesWhenStopped` properties
 *  These properties are automatically managed for you, altering them results in undefined behavior
 */
@interface RTSPlaybackActivityIndicatorView : UIActivityIndicatorView

/**
 *  The media player to which the playback button must be associated with.
 */
@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@end

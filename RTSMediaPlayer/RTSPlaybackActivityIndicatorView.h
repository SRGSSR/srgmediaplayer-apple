//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <UIKit/UIKit.h>

// Forward declarations
@class RTSMediaPlayerController;

/**
 *  An activity indicator displaying the current status of the associated media player controller.
 *
 *  Simply install an instance somewhere onto your custom player interface and bind to a media player
 *  controller
 */
@interface RTSPlaybackActivityIndicatorView : UIActivityIndicatorView

/**
 *  The media player to which the playback button must be associated with.
 */
@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@end

//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//
#import <UIKit/UIKit.h>

// Forward declarations
@class RTSMediaPlayerController;

/**
 *  A play / pause button whose status is automatically synchronized with the media player controller it is attached
 *  to
 *
 *  Simply install an instance somewhere onto your custom player interface and bind to the media player controller which 
 *  needs to be controlled
 */
IB_DESIGNABLE
@interface RTSMediaPlayerPlaybackButton : UIButton

/**
 *  The media player to which the playback button must be associated with.
 */
@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;

/**
 *  Color customization
 */
@property (nonatomic) IBInspectable UIColor *normalColor;
@property (nonatomic) IBInspectable UIColor *hightlightColor;

@end

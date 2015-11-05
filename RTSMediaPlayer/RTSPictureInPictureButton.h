//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

// Forward declarations
@class RTSMediaPlayerController;

/**
 *  Standard button images for starting and stopping picture in picture
 */
FOUNDATION_EXTERN UIImage *RTSPictureInPictureButtonStartImage(void);
FOUNDATION_EXTERN UIImage *RTSPictureInPictureButtonStopImage(void);

/**
 *  A button to toggle picture in picture (if available) for the associated player. This class is not meant to be
 *  subclassed.
 *
 *  Simply install an instance somewhere onto your custom player interface and bind to the media player controller which
 *  the button must be associated with. The button will be hidden automatically if picture in picture is not possible.
 *
 *  It is important that picture in picture is never enabled without user intervention, except when the system does
 *  it automatically from full-screen playback (this is controlled by a system setting). Apple might reject your 
 *  application otherwise.
 */
@interface RTSPictureInPictureButton : UIButton

/**
 *  The media player to which the picture in picture button must be associated with.
 */
@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@end

//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  A button to toggle picture in picture (if available) for the associated player. This class is not meant to be
 *  subclassed.
 *
 *  Simply install an instance somewhere onto your custom player interface and bind to the media player controller which
 *  the button must be associated with. The button will be hidden automatically if picture in picture is not possible.
 *  If your controls are stacked using a `UIStackView`, the layout will automatically adjust when the button appears
 *  or disappears.
 *
 *  It is important that picture in picture is never enabled without user intervention, except when the system does
 *  it automatically from full-screen playback (this is controlled by a system setting). Apple might reject your
 *  application otherwise.
 */
@interface SRGPictureInPictureButton : UIView

/**
 *  The media player which the picture in picture button must be associated with
 */
@property (nonatomic, weak, nullable) IBOutlet SRGMediaPlayerController *mediaPlayerController;

/**
 *  Image customization (default 28x22 images are used if not set)
 *
 *  @discussion The button has an intrinsic size of 28 x 22 pixels. If you change the start and stop images, you might
 *              need to add width and height constraints to tailor the button size to your needs
 */
@property (nonatomic, null_resettable) IBInspectable UIImage *startImage;
@property (nonatomic, null_resettable) IBInspectable UIImage *stopImage;

@end

NS_ASSUME_NONNULL_END

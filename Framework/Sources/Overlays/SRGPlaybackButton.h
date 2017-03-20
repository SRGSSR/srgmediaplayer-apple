//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  A play / pause button whose status is automatically synchronized with the media player controller it is attached
 *  to.
 *
 *  Simply install an instance somewhere onto your custom player interface and bind to the media player controller which
 *  needs to be controlled.
 */
IB_DESIGNABLE
@interface SRGPlaybackButton : UIButton

/**
 *  The media player which the playback button must be associated with.
 */
@property (nonatomic, weak, nullable) IBOutlet SRGMediaPlayerController *mediaPlayerController;

/**
 *  Image customization (default scalable images are used if not set).
 */
@property (nonatomic, null_resettable) IBInspectable UIImage *playImage;
@property (nonatomic, null_resettable) IBInspectable UIImage *pauseImage;

/**
 *  The tint color to apply when the button is highlighted (if nil, then the tint color is applied).
 */
@property (nonatomic, null_resettable) IBInspectable UIColor *highlightedTintColor;

@end

NS_ASSUME_NONNULL_END

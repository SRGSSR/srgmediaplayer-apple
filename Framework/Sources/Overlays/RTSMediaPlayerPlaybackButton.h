//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSMediaPlayerController.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  A play / pause button whose status is automatically synchronized with the media player controller it is attached
 *  to
 *
 *  Simply install an instance somewhere onto your custom player interface and bind to the media player controller which
 *  needs to be controlled
 */
@interface RTSMediaPlayerPlaybackButton : UIButton

/**
 *  The media player to which the playback button must be associated with.
 */
@property (nonatomic, weak, nullable) IBOutlet RTSMediaPlayerController *mediaPlayerController;

/**
 *  Color customization
 */
@property (nonatomic, nullable) IBInspectable UIColor *normalColor;
@property (nonatomic, nullable) IBInspectable UIColor *hightlightColor;

/**
 * Image customization (default images are used if not set)
 */
@property (nonatomic, null_resettable) UIImage *playImage;
@property (nonatomic, null_resettable) UIImage *pauseImage;
@property (nonatomic, null_resettable) UIImage *stopImage;

@end

NS_ASSUME_NONNULL_END

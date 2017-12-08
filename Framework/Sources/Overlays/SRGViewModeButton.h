//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerView.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  A button to change between view modes for the associated player view (@see `SRGMediaPlayerView`), e.g. between
 *  360° and cardboard displays. This class is not meant to be subclassed.
 *
 *  Simply install an instance somewhere onto your custom player interface and bind to the media player view which
 *  the button must be associated with. The button will be hidden automatically if no view mode switch is available.
 *  If your controls are stacked using a `UIStackView`, the layout will automatically adjust when the button appears
 *  or disappears.
 *
 *  The button is automatically shown or hidden by having its `hidden` property automatically adjusted. Attempting
 *  to manually alter this property leads to undefined behavior. You can force the button to always be hidden by
 *  setting its `alwaysHidden` property to `YES` if needed.
 */
IB_DESIGNABLE
@interface SRGViewModeButton : UIView

/**
 *  The media player view which the button must be associated with.
 */
@property (nonatomic, weak, nullable) IBOutlet SRGMediaPlayerView *mediaPlayerView;

/**
 *  Image customization (a default image is used if not set).
 */
@property (nonatomic, null_resettable) IBInspectable UIImage *viewModeMonoscopicImage;
@property (nonatomic, null_resettable) IBInspectable UIImage *viewModeStereoscopicImage;

/**
 *  When set to `YES`, force the button to be always hidden, even if subtitles are available.
 *
 *  Default value is `NO`.
 */
@property (nonatomic, getter=isAlwaysHidden) IBInspectable BOOL alwaysHidden;

@end

NS_ASSUME_NONNULL_END

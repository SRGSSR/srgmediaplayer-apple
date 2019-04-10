//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SRGTracksButton;

/**
 *  Tracks button delegate protocol.
 */
@protocol SRGTracksButtonDelegate <NSObject>

@optional

/**
 *  The button is about to show the selection popover.
 */
- (void)tracksButtonWillShowSelectionPopover:(SRGTracksButton *)tracksButton;

/**
 *  The selection popover has been hidden.
 */
- (void)tracksButtonDidHideSelectionPopover:(SRGTracksButton *)tracksButton;

@end

/**
 *  Button which is automatically shown when subtitles are available, disappears otherwise by default. If your controls are
 *  stacked using a `UIStackView`, the layout will automatically adjust when the button appears or disappears.
 *
 *  The button is automatically shown or hidden by having its `hidden` property automatically adjusted. Attempting
 *  to manually alter this property leads to undefined behavior. You can force the button to always be hidden by
 *  setting its `alwaysHidden` property to `YES` if needed.
 *
 *  A media player controller must be attached. The button is automatically displayed if the media being played has 
 *  subtitles or audio tracks. Tapping on the button displays a list of the available tracks. If one is selected, the
 *  button is set to the selected state (with a corresponding image).
 */
IB_DESIGNABLE
@interface SRGTracksButton : UIView

/**
 *  The media player which the button must be associated with.
 */
@property (nonatomic, weak, nullable) IBOutlet SRGMediaPlayerController *mediaPlayerController;

/**
 *  Image customization (a default image is used if not set).
 */
@property (nonatomic, null_resettable) UIImage *image;
@property (nonatomic, null_resettable) UIImage *selectedImage;

/**
 *  When set to `YES`, force the button to be always hidden, even if subtitles are available.
 *
 *  Default value is `NO`.
 */
@property (nonatomic, getter=isAlwaysHidden) IBInspectable BOOL alwaysHidden;

/**
 *  The button delegate.
 */
@property (nonatomic, weak) id<SRGTracksButtonDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

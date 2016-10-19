//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController.h"

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Button which is automatically shown when Airplay is active, hidden otherwise. If your controls are stacked using a
 *  `UIStackView`, the layout will automatically adjust when the button appears or disappears.
 *
 *  A media player controller can be optionally attached. If Airplay playback mirroring is used (the `AVPlayer`
 *  `usesExternalPlaybackWhileExternalScreenIsActive` property has been set to `NO`), no button will be displayed.
 *  (Airplay can still be enabled from the control center). If no media player controller is attached, the button will 
 *  be displayed for any kind of Airplay usage.
 */
@interface SRGAirplayButton : UIView

/**
 *  The media player to which the button must be associated with.
 */
@property (nonatomic, weak, nullable) IBOutlet SRGMediaPlayerController *mediaPlayerController;

@end

NS_ASSUME_NONNULL_END

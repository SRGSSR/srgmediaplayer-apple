//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  @name Supported view modes.
 */
typedef NS_ENUM(NSInteger, SRGMediaPlayerViewMode) {
    SRGMediaPlayerViewModeFlat = 0,                         // Standard "flat" playback.
    SRGMediaPlayerViewModeMonoscopic,                       // 360 monoscopic playback.
    SRGMediaPlayerViewModeStereoscopic                      // 360 stereoscopic playback (cardboard).
};

/**
 *  The view used by the player to display its media. You can instantiate such views in storyboards or xib files
 *  and bind them to the `view` property of an `SRGMediaPlayerController` instance.
 */
@interface SRGMediaPlayerView : UIView

/**
 *  Set the motion manager to use for device tracking when playing 360° videos. At most one motion manager should
 *  exist per app (see https://developer.apple.com/documentation/coremotion/cmmotionmanager). If your application
 *  already uses its own core motion manager, you can set it using this class method (not that you are then
 *  responsible of starting and stopping tracking, though). Data refresh rate should be at least 1/60 for an optimal
 *  experience.
 *
 *  If no motion manager is provided at the time a media player view requires it, an internal motion manager will
 *  be used. You should set a motion manager before any playback occurs and not change it afterwards, otherwise the
 *  behavior is undefined.
 */

/**
 *  Retrieve or change the current view mode, if any.
 */
@property (nonatomic) SRGMediaPlayerViewMode viewMode;

@end

NS_ASSUME_NONNULL_END

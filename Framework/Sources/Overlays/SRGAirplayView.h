//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController.h"

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class SRGAirplayView;

/**
 *  Airplay view delegate protocol, providing optional customization behaviour to `SRGAirplayView`
 */
@protocol SRGAirplayViewDelegate <NSObject>
@optional

/**
 *  Attributes for the 'Airplay' title. If not implemented, a default style will be applied (bold system font, white,
 *  centered, 14 pts)
 */
- (nullable NSDictionary<NSString *, id> *)airplayViewTitleAttributedDictionary:(SRGAirplayView *)airplayView;

/**
 *  Lets you customize the subtitle displaying the route name. If not implemented, a default message will be used
 */
- (nullable NSString *)airplayView:(SRGAirplayView *)airplayView subtitleForAirplayRouteName:(NSString *)routeName;

/**
 *  Attributes for the route subtitle. If not implemented, a default style will be applied (system font, light gray,
 *  centered, 12 pts)
 */
- (nullable NSDictionary<NSString *, id> *)airplayViewSubtitleAttributedDictionary:(SRGAirplayView *)airplayView;

@end

/**
 *  View automatically displaying whether Airplay playback is active. Simply install somewhere onto your custom player
 *  interface, the view will automatically appear when Airplay playback begins and disappear when it ends.
 *
 *  A media player controller can be optionally attached. If Airplay playback mirroring is used (the `AVPlayer`
 *  `usesExternalPlaybackWhileExternalScreenIsActive` property has been set to `NO`), no overlay will be displayed.
 *  No overlay will be displayed if only audio is sent to a device supporting only audio casting (e.g. Airport express).
 *
 *  If no media player controller is attached, the overlay will be displayed for any kind of Airplay usage.
 *
 *  Further customization is available by using the associated delegate.
 */
@interface SRGAirplayView : UIView <SRGAirplayViewDelegate>

/**
 *  The media player to which the overlay must be associated with.
 */
@property (nonatomic, weak, nullable) IBOutlet SRGMediaPlayerController *mediaPlayerController;

/**
 *  A filling factor for the overlay contents, > 0 and <= 1 (full frame). Defaults to 0.6
 */
@property (nonatomic) IBInspectable CGFloat fillFactor;

/**
 *  An optional delegate for customization
 */
@property (nonatomic, weak, nullable) IBOutlet id<SRGAirplayViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

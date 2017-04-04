//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController.h"

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declarations.
@class SRGAirplayView;

/**
 *  Suggested localized description for the current Airplay route (if any). Can be used by custom overview implementations
 *  to display a standard route description message.
 */
OBJC_EXTERN NSString * _Nullable SRGAirplayRouteDescription(void);

/**
 *  Airplay view delegate protocol, providing optional customization behaviour for the default `SRGAirplayView`
 *  appearance.
 */
@protocol SRGAirplayViewDelegate <NSObject>
@optional

/**
 *  This method is called when the view is shown. Custom views can use this method to update their display with the
 *  new route name.
 */
- (void)airplayView:(SRGAirplayView *)airplayView didShowWithAirplayRouteName:(nullable NSString *)routeName;

/**
 *  This method is called when the view has been hidden.
 */
- (void)airplayViewDidHide:(SRGAirplayView *)airplayView;

/**
 *  Attributes for the 'Airplay' title of the default overlay. If not implemented, a default style will be applied 
 *  (bold system font, white, centered, 14 pts).
 */
- (nullable NSDictionary<NSString *, id> *)airplayViewTitleAttributedDictionary:(SRGAirplayView *)airplayView;

/**
 *  Lets you customize the subtitle displaying the route name on the default overlay. If not implemented, a default 
 *  message will be used.
 */
- (nullable NSString *)airplayViewSubtitle:(SRGAirplayView *)airplayView;

/**
 *  Attributes for the route subtitle on the default overlay. If not implemented, a default style will be applied 
 *  (system font, light gray, centered, 12 pts).
 */
- (nullable NSDictionary<NSString *, id> *)airplayViewSubtitleAttributedDictionary:(SRGAirplayView *)airplayView;

@end

/**
 *  View automatically displayed when Airplay playback is active. Simply install somewhere onto your custom player
 *  interface and the view will automatically appear when Airplay playback begins and disappear when it ends. The
 *  design can be defined using a custom view. If the view is left empty (i.e. without subviews), a default overlay 
 *  apperance (Airplay icon with text displaying the route) will be used, which can be further customized through 
 *  the `SRGAirplayViewDelegate` protocol.
 *
 *  A media player controller can be optionally attached. If Airplay playback mirroring is used (the `AVPlayer`
 *  `usesExternalPlaybackWhileExternalScreenIsActive` property has been set to `NO`), no overlay will be displayed.
 *  No overlay will be displayed if only audio is sent to a device supporting only audio casting (e.g. Airport express).
 *
 *  If no media player controller is attached, the overlay will be displayed for any kind of Airplay usage.
 *
 *  Further customization is available by using the associated delegate.
 */
IB_DESIGNABLE
@interface SRGAirplayView : UIView <SRGAirplayViewDelegate>

/**
 *  The media player which the overlay must be associated with.
 */
@property (nonatomic, weak, nullable) IBOutlet SRGMediaPlayerController *mediaPlayerController;

/**
 *  An optional delegate for customization of the default appearance.
 */
@property (nonatomic, weak, nullable) IBOutlet id<SRGAirplayViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

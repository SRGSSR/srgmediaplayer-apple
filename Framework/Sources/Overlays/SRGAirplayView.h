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
 *  Airplay view delegate protocol, providing optional customization behaviour for the default `SRGAirplayView`
 *  appearance. These methods are ignored if a custom layout is used
 */
@protocol SRGAirplayViewDelegate <NSObject>
@optional

/**
 *  Attributes for the 'Airplay' title of the default overlay. If not implemented, a default style will be applied 
 *  (bold system font, white, centered, 14 pts)
 *
 *  @discussion This method is ignored is `-airplayView:customViewForAirplayRouteName:` returns a custom view
 */
- (nullable NSDictionary<NSString *, id> *)airplayViewTitleAttributedDictionary:(SRGAirplayView *)airplayView;

/**
 *  Lets you customize the subtitle displaying the route name on the default overlay. If not implemented, a default 
 *  message will be used
 *
 *  @discussion This method is ignored is `-airplayView:customViewForAirplayRouteName:` returns a custom view
 */
- (nullable NSString *)airplayView:(SRGAirplayView *)airplayView subtitleForAirplayRouteName:(NSString *)routeName;

/**
 *  Attributes for the route subtitle on the default overlay. If not implemented, a default style will be applied 
 *  (system font, light gray, centered, 12 pts)
 *
 *  @discussion This method is ignored is `-airplayView:customViewForAirplayRouteName:` returns a custom view
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
@interface SRGAirplayView : UIView <SRGAirplayViewDelegate>

/**
 *  The media player which the overlay must be associated with
 */
@property (nonatomic, weak, nullable) IBOutlet SRGMediaPlayerController *mediaPlayerController;

/**
 *  An optional delegate for customization of the default appearance
 */
@property (nonatomic, weak, nullable) IBOutlet id<SRGAirplayViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

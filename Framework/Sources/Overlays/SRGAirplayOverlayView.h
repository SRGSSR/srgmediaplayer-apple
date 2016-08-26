//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class SRGAirplayOverlayView;

/**
 *  Airplay view data source protocol, providing optional customization mechanism to `RTSAirplayOverlayView`
 */
@protocol RTSAirplayOverlayViewDataSource <NSObject>
@optional

/**
 *  Attributes for the 'Airplay' title. If not implemented, a default style will be applied (bold system font, white,
 *  centered, 14 pts)
 */
- (NSDictionary *)airplayOverlayViewTitleAttributedDictionary:(SRGAirplayOverlayView *)airplayOverlayView;

/**
 *  Lets you customize how the subtitle displaying the route name is displayed. If not implemented, a default message
 *  will be used
 */
- (NSString *)airplayOverlayView:(SRGAirplayOverlayView *)airplayOverlayView subtitleForAirplayRouteName:(NSString *)routeName;

/**
 *  Attributes for the route subtitle. If not implemented, a default style will be applied (system font, light gray,
 *  centered, 12 pts)
 */
- (NSDictionary *)airplayOverlayViewSubtitleAttributedDictionary:(SRGAirplayOverlayView *)airplayOverlayView;

@end

/**
 *  Airplay view delegate protocol, providing optional customization behaviour to `RTSAirplayOverlayView`
 */
@protocol SRGAirplayOverlayViewDelegate <NSObject>
@optional

/**
 *  The view is hidden or not, depending of the AVAudioSession current route, output port.
 *  In case you want to not show it, because of routing just audio, you can force to hide it.
 *  Example: Use it with isExternalPlaybackActive on the AVPlayer you want.
 *  By defaut, returning YES.
 */
- (BOOL)airplayOverlayViewCouldBeDisplayed:(SRGAirplayOverlayView *)airplayOverlayView;

@end

/**
 *  View automatically displaying whether Airplay playback is being made. Simply install somewhere onto your custom player
 *  interface, the view will automatically appear when Airplay playback begins and disappear when it ends
 */
@interface SRGAirplayOverlayView : UIView <RTSAirplayOverlayViewDataSource>

/**
 * A filling factor for the overlay contents, > 0 and <= 1 (full frame). Defaults to 0.6
 */
@property (nonatomic) IBInspectable CGFloat fillFactor;

/**
 *  An optional data source for customization
 */
@property (nonatomic, weak, nullable) IBOutlet id<RTSAirplayOverlayViewDataSource> dataSource;

/**
 *  An optional delegate for customization
 */
@property (nonatomic, weak, nullable) IBOutlet id<SRGAirplayOverlayViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

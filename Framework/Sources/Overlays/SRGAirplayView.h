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
@class SRGAirplayView;

/**
 *  Airplay view data source protocol, providing optional customization mechanism to `RTSAirplayView`
 */
@protocol RTSAirplayViewDataSource <NSObject>
@optional

/**
 *  Attributes for the 'Airplay' title. If not implemented, a default style will be applied (bold system font, white,
 *  centered, 14 pts)
 */
- (nullable NSDictionary<NSString *, id> *)airplayViewTitleAttributedDictionary:(SRGAirplayView *)airplayView;

/**
 *  Lets you customize how the subtitle displaying the route name is displayed. If not implemented, a default message
 *  will be used
 */
- (nullable NSString *)airplayView:(SRGAirplayView *)airplayView subtitleForAirplayRouteName:(NSString *)routeName;

/**
 *  Attributes for the route subtitle. If not implemented, a default style will be applied (system font, light gray,
 *  centered, 12 pts)
 */
- (nullable NSDictionary<NSString *, id> *)airplayViewSubtitleAttributedDictionary:(SRGAirplayView *)airplayView;

@end

/**
 *  Airplay view delegate protocol, providing optional customization behaviour to `RTSAirplayView`
 */
@protocol SRGAirplayViewDelegate <NSObject>
@optional

/**
 *  The view is hidden or not, depending of the AVAudioSession current route, output port.
 *  In case you want to not show it, because of routing just audio, you can force to hide it.
 *  Example: Use it with isExternalPlaybackActive on the AVPlayer you want.
 *  By defaut, returning YES.
 */
- (BOOL)airplayViewCouldBeDisplayed:(SRGAirplayView *)airplayView;

@end

/**
 *  View automatically displaying whether Airplay playback is being made. Simply install somewhere onto your custom player
 *  interface, the view will automatically appear when Airplay playback begins and disappear when it ends
 */
@interface SRGAirplayView : UIView <RTSAirplayViewDataSource>

/**
 * A filling factor for the overlay contents, > 0 and <= 1 (full frame). Defaults to 0.6
 */
@property (nonatomic) IBInspectable CGFloat fillFactor;

/**
 *  An optional data source for customization
 */
@property (nonatomic, weak, nullable) IBOutlet id<RTSAirplayViewDataSource> dataSource;

/**
 *  An optional delegate for customization
 */
@property (nonatomic, weak, nullable) IBOutlet id<SRGAirplayViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

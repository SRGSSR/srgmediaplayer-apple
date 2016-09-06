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
 *  Airplay view delegate protocol, providing optional customization behaviour to `SRGAirplayView`
 */
@protocol SRGAirplayViewDelegate <NSObject>
@optional

/**
 *  By default the Airplay overlay is displayed when external playback is active. You can override this behavior
 *  if you do not want to display the view in some cases (e.g. routing only audio)
 *
 *  If not implemented, the Airplay overlay behaves as if this method returns YES
 */
- (BOOL)airplayViewShouldBeDisplayed:(SRGAirplayView *)airplayView;

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
 *  interface, the view will automatically appear when Airplay playback begins and disappear when it ends
 *
 *  Further customization is available by using the associated delegate.
 */
@interface SRGAirplayView : UIView <SRGAirplayViewDelegate>

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

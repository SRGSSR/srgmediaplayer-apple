//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

// Forward declarations
@class RTSAirplayOverlayView;

/**
 *  Airplay view data source protocol
 */
@protocol RTSAirplayOverlayViewDataSource <NSObject>
@optional

/**
 *  Attributes for the 'Airplay' title
 */
- (NSDictionary *)airplayOverlayViewTitleAttributedDictionary:(RTSAirplayOverlayView *)airplayOverlayView;

/**
 *  Lets you customize how the subtitle displaying the route name is displayed
 */
- (NSString *)airplayOverlayView:(RTSAirplayOverlayView *)airplayOverlayView subtitleForAirplayRouteName:(NSString *)routeName;

/**
 *  Attributes for the route subtitle
 */
- (NSDictionary *)airplayOverlayViewSubitleAttributedDictionary:(RTSAirplayOverlayView *)airplayOverlayView;

@end

/**
 *  View automatically displaying whether Airplay playback is being made. Simply install somewhere onto your custom player
 *  interface, the view will automatically appear when Airplay playback begins and disappeear when it ends
 */
@interface RTSAirplayOverlayView : UIView

/**
 *  An optional data source for customization
 */
@property (nonatomic, weak) IBOutlet id<RTSAirplayOverlayViewDataSource> dataSource;

@end

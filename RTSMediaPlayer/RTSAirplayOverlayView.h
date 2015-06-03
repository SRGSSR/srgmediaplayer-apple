//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@class RTSAirplayOverlayView;

@protocol RTSAirplayOverlayViewDataSource <NSObject>
@optional

- (NSDictionary *) airplayOverlayViewTitleAttributedDictionary:(RTSAirplayOverlayView *)airplayOverlayView;

- (NSString *) airplayOverlayView:(RTSAirplayOverlayView *)airplayOverlayView subtitleForAirplayRouteName:(NSString *)routeName;
- (NSDictionary *) airplayOverlayViewSubitleAttributedDictionary:(RTSAirplayOverlayView *)airplayOverlayView;

@end

@interface RTSAirplayOverlayView : UIView

@property (nonatomic, weak) IBOutlet id<RTSAirplayOverlayViewDataSource> dataSource;

@end

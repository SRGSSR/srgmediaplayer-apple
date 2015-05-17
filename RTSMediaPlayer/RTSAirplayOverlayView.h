//
//  Created by Frédéric Humbert-Droz on 17/05/15.
//  Copyright (c) 2015 RTS. All rights reserved.
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

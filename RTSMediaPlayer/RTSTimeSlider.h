//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>
#import <RTSMediaPlayer/RTSMediaPlayback.h>

@class RTSMediaPlayerController;
@protocol RTSTimeSliderDelegate;

@interface RTSTimeSlider : UISlider

@property (nonatomic, weak) IBOutlet id<RTSMediaPlayback> playbackController;
@property (nonatomic, weak) IBOutlet id<RTSTimeSliderDelegate> slidingDelegate;

@property (nonatomic, weak) IBOutlet UILabel *timeLeftValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *valueLabel;

@property (nonatomic, strong) UIColor *borderStrokeColor;
@property (nonatomic, strong) UIColor *minimumValueFillColor;
@property (nonatomic, strong) UIColor *emptyFillColor;

@end

@protocol RTSTimeSliderDelegate <NSObject>

- (void)timeSlider:(RTSTimeSlider *)slider isSlidingAtPlaybackTime:(CMTime)time withValue:(CGFloat)value;

@end
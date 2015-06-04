//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>
#import <RTSMediaPlayer/RTSMediaPlayback.h>

@class RTSMediaPlayerController;
@protocol RTSTimeSliderSeekingDelegate;

@interface RTSTimeSlider : UISlider

@property (nonatomic, weak) IBOutlet id<RTSMediaPlayback> playbackController;
@property (nonatomic, weak) IBOutlet id<RTSTimeSliderSeekingDelegate> seekingDelegate;

@property (nonatomic, weak) IBOutlet UILabel *timeLeftValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *valueLabel;

@end

@protocol RTSTimeSliderSeekingDelegate <NSObject>

- (void)timeSlider:(RTSTimeSlider *)slider isSeekingAtTime:(CMTime)time withValue:(CGFloat)value;

@end
//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>
#import <SRGMediaPlayer/RTSMediaPlayback.h>

@class RTSMediaPlayerController;
@protocol RTSTimeSliderDelegate;

/**
 * The slider can be customized as follows:
 *   - borderColor: Color of the small border around the non-elapsed time track (defaults to black)
 *   - minimumTrackTintColor: Elapsed time track color (defaults to white)
 *   - maximumTrackTintColor: Preloaded track color (defaults to black)
 *   - thumbTintColor: Thumb color (defaults to white)
 */
@interface RTSTimeSlider : UISlider

@property (nonatomic, weak) IBOutlet id<RTSMediaPlayback> playbackController;
@property (nonatomic, weak) IBOutlet id<RTSTimeSliderDelegate> slidingDelegate;

@property (nonatomic, weak) IBOutlet UILabel *timeLeftValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *valueLabel;

// Defaults to black
@property (nonatomic, strong) IBInspectable UIColor *borderColor;

@end

@protocol RTSTimeSliderDelegate <NSObject>

- (void)timeSlider:(RTSTimeSlider *)slider isSlidingAtPlaybackTime:(CMTime)time withValue:(CGFloat)value;

@end

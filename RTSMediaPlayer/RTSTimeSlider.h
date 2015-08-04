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

/**
 *  The playback controller attached to the slider
 */
@property (nonatomic, weak) IBOutlet id<RTSMediaPlayback> playbackController;

/**
 *  The delegate receiving slider events
 */
@property (nonatomic, weak) IBOutlet id<RTSTimeSliderDelegate> slidingDelegate;

/**
 *  Must be bound to the label displaying the remaining time
 */
@property (nonatomic, weak) IBOutlet UILabel *timeLeftValueLabel;

/**
 *  Must be bound to the label displaying the current time
 */
@property (nonatomic, weak) IBOutlet UILabel *valueLabel;

/**
 *  Bar border color (defaults to black)
 */
@property (nonatomic, strong) IBInspectable UIColor *borderColor;

/**
 *  The current time
 */
@property (nonatomic, readonly) CMTime time;

/**
 *  Return YES iff the current slider position matches the conditions of a live feed
 */
@property (nonatomic, readonly, getter=isLive) BOOL live;

@end

@protocol RTSTimeSliderDelegate <NSObject>

- (void)timeSlider:(RTSTimeSlider *)slider isMovingToPlaybackTime:(CMTime)time withValue:(CGFloat)value interactive:(BOOL)interactive;

@end

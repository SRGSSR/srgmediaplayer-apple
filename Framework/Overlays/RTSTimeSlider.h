//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>

/**
 *  The slider knob position when a live stream is played (the knob itself cannot be moved). The default value is left,
 *  as for the standard iOS playback controller
 */
typedef NS_ENUM(NSInteger, RTSTimeSliderLiveKnobPosition) {
	RTSTimeSliderLiveKnobPositionDefault = 0,
	RTSTimeSliderLiveKnobPositionLeft = RTSTimeSliderLiveKnobPositionDefault,
	RTSTimeSliderLiveKnobPositionRight
};

// Forward declarations
@class RTSMediaPlayerController;
@protocol RTSTimeSliderDelegate;

/**
 *  A slider displaying the playback position of the associated playback controller (with optional time and remaining
 *  time labels) and providing a way to seek at any position. The slider also displays which part of the video is
 *  already in the buffer
 *
 *  Simply install an instance somewhere onto your custom player interface and bind to either a media player controller
 *  or a segments controller (if you need to support segments). You can also bind two labels for displaying the time
 *  and the remaining time.
 *
 *  The slider can be customized as follows:
 *    - `borderColor`: Color of the small border around the non-elapsed time track (defaults to black)
 *    - `minimumTrackTintColor`: Elapsed time track color (defaults to white)
 *    - `maximumTrackTintColor`: Preloaded track color (defaults to black)
 *    - `thumbTintColor`: Thumb color (defaults to white)
 */
@interface RTSTimeSlider : UISlider

/**
 *  The playback controller attached to the slider
 */
@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;

/**
 *  The delegate receiving slider events
 */
@property (nonatomic, weak) IBOutlet id<RTSTimeSliderDelegate> slidingDelegate;

/**
 *  Outlet which must be bound to the label displaying the remaining time
 */
@property (nonatomic, weak) IBOutlet UILabel *timeLeftValueLabel;

/**
 *  Outlet which must be bound to the label displaying the current time
 */
@property (nonatomic, weak) IBOutlet UILabel *valueLabel;

/**
 *  Bar border color (defaults to black)
 */
@property (nonatomic, strong) IBInspectable UIColor *borderColor;

/**
 *  The time corresponding to the current slider position
 *
 *  @discussion While dragging, this property may not reflect the value current time property of the asset being played.
 *              The slider live property namely reflects the current slider knob status, not the controller status
 */
@property (nonatomic, readonly) CMTime time;

/**
 *  Return YES iff the current slider position matches the conditions of a live feed
 *
 *  @discussion While dragging, this property may not reflect the value returned by the RTSMediaPlayback live property.
 *              The slider live property namely reflects the current slider knob status, not the controller status
 */
@property (nonatomic, readonly, getter=isLive) BOOL live;

/**
 *  Set to YES to have the player seek when the slider knob is moved, or to NO if seeking must be performed only
 *  after the knob was released
 *
 *  Defaults to YES
 */
@property (nonatomic, assign, getter=isSeekingDuringTracking) BOOL seekingDuringTracking;

/**
 *  The position of the slider knob when playing a live stream. Defaults to RTSTimeSliderLiveKnobPositionDefault (left
 *  position)
 */
@property (nonatomic, assign) RTSTimeSliderLiveKnobPosition knobLivePosition;

@end

/**
 *  Protocol describing events associated with the slider
 */
@protocol RTSTimeSliderDelegate <NSObject>

/**
 *  Called when the slider is moved, either interactively or as the result of an item being played
 *
 *  @param slider      The slider for which the event is received
 *  @param time        The time at which the slider was moved
 *  @param value       The corresponding slider value
 *  @param interactive Whether the change is a result of a user interfaction (YES) or not
 */
- (void)timeSlider:(RTSTimeSlider *)slider isMovingToPlaybackTime:(CMTime)time withValue:(CGFloat)value interactive:(BOOL)interactive;

@end

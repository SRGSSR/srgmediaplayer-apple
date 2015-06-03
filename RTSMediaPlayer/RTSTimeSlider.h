//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>
#import <RTSMediaPlayer/RTSMediaPlayback.h>

@class RTSMediaPlayerController;

@interface RTSTimeSlider : UISlider

@property (nonatomic, weak) IBOutlet id<RTSMediaPlayback> playbackController;

@property (nonatomic, weak) IBOutlet UILabel *timeLeftValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *valueLabel;

/**
 *  Return the time currently displayed by the slider
 */
@property (nonatomic, readonly) CMTime time;

@end

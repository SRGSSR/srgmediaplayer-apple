//
//  Created by Frédéric Humbert-Droz on 06/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>

@class RTSMediaPlayerController;

@interface RTSTimeSlider : UISlider

/**
 *  <#Description#>
 */
@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@property (nonatomic, weak) IBOutlet UILabel *timeLeftValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *valueLabel;

/**
 *  Return the time currently displayed by the slider
 */
@property (nonatomic, readonly) CMTime time;

@end

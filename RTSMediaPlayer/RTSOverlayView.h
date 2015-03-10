//
//  Created by Frédéric Humbert-Droz on 06/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RTSMediaPlayer/RTSOverlayViewProtocol.h>

@interface RTSOverlayView : UIView <RTSOverlayViewProtocol>

/**
 *  <#Description#>
 */
- (void) show;

/**
 *  <#Description#>
 */
- (void) hide;

@end

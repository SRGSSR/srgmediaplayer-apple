//
//  Created by Frédéric Humbert-Droz on 05/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RTSMediaPlayerController;

IB_DESIGNABLE
@interface RTSMediaPlayerPlaybackButton : UIButton

/**
 *  <#Description#>
 */
@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@property (nonatomic) IBInspectable UIColor *normalColor;
@property (nonatomic) IBInspectable UIColor *hightlightColor;

@end

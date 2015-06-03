//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
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

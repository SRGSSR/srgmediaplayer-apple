//
//  Created by Frédéric Humbert-Droz on 06/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RTSMediaPlayerController;

@protocol RTSOverlayViewProtocol <NSObject>

@required
- (void) mediaPlayerController:(RTSMediaPlayerController*)mediaPlayerController overlayHidden:(BOOL)hidden;

@end

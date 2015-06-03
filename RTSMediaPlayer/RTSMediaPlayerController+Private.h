//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "RTSMediaPlayerController.h"
#import <TransitionKit/TransitionKit.h>

@interface RTSMediaPlayerController (Private)

- (void)fireSeekEventWithUserInfo:(NSDictionary *)userInfo;

@end

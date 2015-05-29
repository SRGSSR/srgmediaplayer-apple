//
//  Created by Cédric Luthi on 25.02.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RTSMediaPlayerController;

@protocol RTSMediaPlayerControllerDataSource <NSObject>

- (void) mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController contentURLForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSURL *contentURL, NSError *error))completionHandler;

@end

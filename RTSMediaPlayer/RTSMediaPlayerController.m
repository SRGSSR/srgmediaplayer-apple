//
//  Created by Cédric Luthi on 25.02.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSMediaPlayerController.h"

NSString * const RTSMediaPlayerPlaybackDidFinishNotification = @"RTSMediaPlayerPlaybackDidFinish";
NSString * const RTSMediaPlayerPlaybackStateDidChangeNotification = @"RTSMediaPlayerPlaybackStateDidChange";
NSString * const RTSMediaPlayerNowPlayingMediaDidChangeNotification = @"RTSMediaPlayerNowPlayingMediaDidChange";

@implementation RTSMediaPlayerController

- (instancetype) initWithContentURL:(NSURL *)contentURL
{
	return [self initWithContentIdentifier:@"" dataSource:(id<RTSMediaPlayerControllerDataSource>)self];
}

- (instancetype) initWithContentIdentifier:(NSString *)identifier dataSource:(id<RTSMediaPlayerControllerDataSource>)dataSource
{
	return nil;
}

- (void) play
{
	
}

- (void) playIdentifier:(NSString *)identifier
{
	
}

- (void) pause
{
	
}

- (void) seekToTime:(NSTimeInterval)time
{
	
}

@end

//
// CSStreamSenseMPMoviePlayerControllerPlugin.h
// comScore
//
// Copyright 2014 comScore, Inc. All right reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "CSStreamSensePlugin.h"

@interface CSStreamSenseMPMoviePlayerControllerPlugin : CSStreamSensePlugin

- (id)initWithPlayer:(MPMoviePlayerController *)moviePlayerController;

@end
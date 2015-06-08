//
//  CSStreamSenseAVPlayerPlugin.h
//  comScore
//
// Copyright 2014 comScore, Inc. All right reserved.
//

#import "CSStreamSensePlugin.h"
#import <AVFoundation/AVFoundation.h>
#import "CSStreamSensePluginProtocol.h"

@interface CSStreamSenseAVPlayerPlugin : CSStreamSensePlugin <CSStreamSensePluginProtocol>

- (id)initWithPlayerLayer:(AVPlayerLayer *)avPlayerLayer;
- (id)initWithPlayer:(AVPlayer *)avPlayer;

@end

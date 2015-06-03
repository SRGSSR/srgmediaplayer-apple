//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <Foundation/Foundation.h>
#import <RTSMediaPlayer/RTSMediaPlayerControllerDataSource.h>
#import <RTSMediaPlayer/RTSMediaSegmentsDataSource.h>

@interface PseudoILDataProvider : NSObject <RTSMediaPlayerControllerDataSource, RTSMediaSegmentsDataSource>

@end

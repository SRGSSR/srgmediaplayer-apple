//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <Foundation/Foundation.h>
#import <SRGMediaPlayer/RTSMediaPlayerControllerDataSource.h>
#import <SRGMediaPlayer/RTSMediaSegmentsDataSource.h>

@interface PseudoILDataProvider : NSObject <RTSMediaPlayerControllerDataSource, RTSMediaSegmentsDataSource>

@end

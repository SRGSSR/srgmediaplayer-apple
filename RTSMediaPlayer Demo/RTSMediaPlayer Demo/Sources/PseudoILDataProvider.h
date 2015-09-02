//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>
#import <SRGMediaPlayer/RTSMediaPlayerControllerDataSource.h>
#import <SRGMediaPlayer/RTSMediaSegmentsDataSource.h>

@interface PseudoILDataProvider : NSObject <RTSMediaPlayerControllerDataSource, RTSMediaSegmentsDataSource>

@end

//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGMediaPlayer/RTSMediaPlayerControllerDataSource.h>
#import <SRGMediaPlayer/RTSMediaSegmentsDataSource.h>
#import <Foundation/Foundation.h>

@interface SwissTXTDataSource : NSObject <RTSMediaPlayerControllerDataSource, RTSMediaSegmentsDataSource>

+ (NSURL *) thumbnailURLForIdentifier:(NSString *)identifier;

@end

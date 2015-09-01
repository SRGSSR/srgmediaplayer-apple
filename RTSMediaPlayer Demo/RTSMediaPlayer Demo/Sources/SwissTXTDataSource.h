//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <SRGMediaPlayer/RTSMediaPlayerControllerDataSource.h>
#import <SRGMediaPlayer/RTSMediaSegmentsDataSource.h>
#import <Foundation/Foundation.h>

@interface SwissTXTDataSource : NSObject <RTSMediaPlayerControllerDataSource, RTSMediaSegmentsDataSource>

+ (NSURL *) thumbnailURLForIdentifier:(NSString *)identifier;

@end

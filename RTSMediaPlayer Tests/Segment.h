//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface Segment : NSObject <RTSMediaSegment>

- (instancetype)initWithIdentifier:(NSString *)identifier timeRange:(CMTimeRange)timeRange fullLength:(BOOL)fullLength;

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *segmentIdentifier;
@property (nonatomic) CMTimeRange timeRange;
@property (nonatomic, getter=isFullLength) BOOL fullLength;
@property (nonatomic, getter=isBlocked) BOOL blocked;
@property (nonatomic, getter=isVisible) BOOL visible;

@end

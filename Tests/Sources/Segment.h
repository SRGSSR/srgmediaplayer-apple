//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

@interface Segment : NSObject <SRGSegment>

+ (Segment *)segmentWithTimeRange:(CMTimeRange)timeRange;
+ (Segment *)blockedSegmentWithTimeRange:(CMTimeRange)timeRange;
+ (Segment *)hiddenSegmentWithTimeRange:(CMTimeRange)timeRange;

- (instancetype)initWithTimeRange:(CMTimeRange)timeRange;

@end

NS_ASSUME_NONNULL_END

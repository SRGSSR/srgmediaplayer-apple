//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "Segment.h"

@interface SwissTXTSegment : Segment

- (instancetype) initWithTimeRange:(CMTimeRange)timeRange title:(NSString *)title identifier:(NSString *)identifier date:(NSDate *)date NS_DESIGNATED_INITIALIZER;
- (instancetype) initWithTime:(CMTime)time title:(NSString *)title identifier:(NSString *)identifier date:(NSDate *)date;

@property (nonatomic, readonly, copy) NSString *identifier;
@property (nonatomic, readonly) UIImage *iconImage;
@property (nonatomic, readonly) NSDate *date;

@end

@interface SwissTXTSegment (UnavailableMethods)

- (instancetype) initWithTimeRange:(CMTimeRange)timeRange title:(NSString *)title NS_UNAVAILABLE;

@end

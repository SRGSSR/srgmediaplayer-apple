//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Segment : NSObject <SRGSegment>

- (instancetype)initWithName:(NSString *)name timeRange:(CMTimeRange)timeRange NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithName:(NSString *)name time:(CMTime)time;
- (instancetype)initWithName:(NSString *)name start:(NSTimeInterval)start duration:(NSTimeInterval)duration;

@property (nonatomic, readonly, copy) NSString *name;

@property (nonatomic, readonly, copy) NSString *durationString;
@property (nonatomic, readonly, copy) NSString *timestampString;

@property (nonatomic, getter=isBlocked) BOOL blocked;           // Default is NO

@end

NS_ASSUME_NONNULL_END

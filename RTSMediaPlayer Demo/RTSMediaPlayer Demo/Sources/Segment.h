//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <UIKit/UIKit.h>

@interface Segment : NSObject <RTSMediaSegment>

- (instancetype) initWithTimeRange:(CMTimeRange)timeRange title:(NSString *)title NS_DESIGNATED_INITIALIZER;

- (instancetype) initWithTime:(CMTime)time title:(NSString *)title;
- (instancetype) initWithStart:(NSTimeInterval)start duration:(NSTimeInterval)duration title:(NSString *)title;

@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly) NSURL *thumbnailURL;

@property (nonatomic, readonly, copy) NSString *durationString;
@property (nonatomic, readonly, copy) NSString *timestampString;

// Default is NO
@property (nonatomic, getter=isFullLength) BOOL fullLength;

// Default is NO
@property (nonatomic, getter=isBlocked) BOOL blocked;

// Default is YES
@property (nonatomic, getter=isVisible) BOOL visible;

@end

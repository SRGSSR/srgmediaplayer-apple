//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <RTSMediaPlayer/RTSMediaPlayerSegment.h>
#import <UIKit/UIKit.h>

@interface Segment : NSObject <RTSMediaPlayerSegment>

- (instancetype) initWithTimeRange:(CMTimeRange)timeRange title:(NSString *)title NS_DESIGNATED_INITIALIZER;

- (instancetype) initWithTime:(CMTime)time title:(NSString *)title;
- (instancetype) initWithStart:(NSTimeInterval)start duration:(NSTimeInterval)duration title:(NSString *)title;

@property (nonatomic, readonly, copy) NSString *title;

// Default is NO
@property (nonatomic, getter=isBlocked) BOOL blocked;

// Default is YES
@property (nonatomic, getter=isVisible) BOOL visible;

@property (nonatomic, readonly) NSURL *thumbnailURL;

@end

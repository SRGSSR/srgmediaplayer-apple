//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <UIKit/UIKit.h>

@interface Segment : NSObject <RTSMediaSegment>

- (instancetype) initWithIdentifier:(NSString *)identifier name:(NSString *)name timeRange:(CMTimeRange)timeRange NS_DESIGNATED_INITIALIZER;

- (instancetype) initWithIdentifier:(NSString *)identifier name:(NSString *)name time:(CMTime)time;
- (instancetype) initWithIdentifier:(NSString *)identifier name:(NSString *)name start:(NSTimeInterval)start duration:(NSTimeInterval)duration;

@property (nonatomic, readonly, copy) NSString *name;
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

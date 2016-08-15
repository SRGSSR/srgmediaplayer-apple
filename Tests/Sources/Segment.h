//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface Segment : NSObject <RTSMediaSegment>

- (instancetype)initWithIdentifier:(NSString *)identifier name:(NSString *)name timeRange:(CMTimeRange)timeRange;

@property (nonatomic, readonly, copy) NSString *name;

@property (nonatomic, getter=isLogical) BOOL logical;				// Default is NO
@property (nonatomic, getter=isBlocked) BOOL blocked;				// Default is NO
@property (nonatomic, getter=isVisible) BOOL visible;				// Default is YES

@end

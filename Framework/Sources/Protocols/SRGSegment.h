//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SRGSegment <NSObject>

@property (nonatomic, readonly) CMTimeRange timeRange;
@property (nonatomic, readonly, getter = isBlocked) BOOL blocked;

@end

NS_ASSUME_NONNULL_END

//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <AVFoundation/AVFoundation.h>
#import <libextobjc/EXTScope.h>

#import "RTSMediaPlayerController.h"
#import "RTSMediaSegment.h"
#import "RTSMediaSegmentsController.h"
#import "RTSMediaPlayerLogger.h"

#import <objc/runtime.h>

static void *RTSMediaSegmentFullLengthKey = &RTSMediaSegmentFullLengthKey;

NSTimeInterval const RTSMediaPlaybackTickInterval = 0.1;
NSString * const RTSMediaPlaybackSegmentDidChangeNotification = @"RTSMediaPlaybackSegmentDidChangeNotification";
NSString * const RTSMediaPlaybackSegmentChangeSegmentInfoKey = @"RTSMediaPlaybackSegmentChangeSegmentInfoKey";
NSString * const RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey = @"RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey";
NSString * const RTSMediaPlaybackSegmentChangeValueInfoKey = @"RTSMediaPlaybackSegmentChangeValueInfoKey";
NSString * const RTSMediaPlaybackSegmentChangeUserSelectInfoKey = @"RTSMediaPlaybackSegmentChangeUserSelectInfoKey";

@interface RTSMediaSegmentsController ()
@property(nonatomic, strong) NSArray *segments;
@property(nonatomic, strong) id playerTimeObserver;
@property(nonatomic, weak) id<RTSMediaSegment> lastPlaybackPositionSegment;
@end

@implementation RTSMediaSegmentsController

+ (NSArray *)sanitizeSegments:(NSArray *)segments
{
    if (segments.count == 0) {
        return segments;
    }
    
    NSMutableArray *sanitizedSegments = [NSMutableArray arrayWithArray:segments];
    
    NSArray *segmentIdentifiers = [segments valueForKeyPath:@"@distinctUnionOfObjects.segmentIdentifier"];
    for (NSString *identifier in segmentIdentifiers) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"segmentIdentifier == %@", identifier];
        NSArray *segmentsForIdentifier = [segments filteredArrayUsingPredicate:predicate];
        
        // The full length is the longest available segment (might not start at 0)
        id<RTSMediaSegment> fullLengthSegment = [segmentsForIdentifier sortedArrayUsingComparator:^NSComparisonResult(id<RTSMediaSegment> _Nonnull segment1, id<RTSMediaSegment> _Nonnull segment2) {
            return CMTimeCompare(segment1.timeRange.duration, segment2.timeRange.duration);
        }].lastObject;
        
        // No full length found. Remove the segment family
        if (!fullLengthSegment) {
            RTSMediaPlayerLogError(@"The segments %@ do not contain any full length and were thus discarded", segmentsForIdentifier);
            [sanitizedSegments removeObjectsInArray:segmentsForIdentifier];
            continue;
        }
        [self markFullLengthSegment:fullLengthSegment];
        
        // Discard those segments which are not contained within the full length
        for (id<RTSMediaSegment> segment in segmentsForIdentifier) {
            if (segment == fullLengthSegment) {
                continue;
            }
            
            if (!CMTimeRangeContainsTimeRange(fullLengthSegment.timeRange, segment.timeRange)) {
                RTSMediaPlayerLogError(@"The segment %@ is not contained in the associated full length %@ and was thus discarded", segment, fullLengthSegment);
                [sanitizedSegments removeObject:segment];
            }
        }
    }
    
    return [sanitizedSegments copy];
}

+ (void)markFullLengthSegment:(id<RTSMediaSegment>)segment
{
    objc_setAssociatedObject(segment, RTSMediaSegmentFullLengthKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (BOOL)isFullLengthSegment:(id<RTSMediaSegment>)segment
{
    return [objc_getAssociatedObject(segment, RTSMediaSegmentFullLengthKey) boolValue];
}

- (void)reloadSegmentsForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSError *error))completionHandler
{
    NSParameterAssert(identifier);
    
    if (!self.playerController) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"Trying to reload data requires to have a player controller."
                                     userInfo:nil];
    }
    
    if (!self.dataSource) {
        self.segments = [NSArray new];
    }
    
    [self removeBlockingTimeObserver];
	
    self.lastPlaybackPositionSegment = nil;
    
    RTSMediaSegmentsCompletionHandler reloadCompletionBlock = ^(NSArray *segments, NSError *error) {
        if (error) {
            if (completionHandler) {
                completionHandler(error);
            }
            return;
        }
        
        self.segments = [RTSMediaSegmentsController sanitizeSegments:segments];
        
        [self addBlockingTimeObserver];
        
        if (completionHandler) {
            completionHandler(nil);
        }
    };
    
    [self.dataSource segmentsController:self segmentsForIdentifier:identifier withCompletionHandler:reloadCompletionBlock];
}

- (void)removeBlockingTimeObserver
{
    if (self.playerController && self.playerTimeObserver) {
        [self.playerController removePeriodicTimeObserver:self.playerTimeObserver];
        self.playerTimeObserver = nil;
    }
}

- (void)addBlockingTimeObserver
{
    @weakify(self);
    
    // This block will necessarily run on the main thread. See addPeriodicTimeObserverForInterval:... method.
    void (^checkBlock)(CMTime) = ^(CMTime time) {
        @strongify(self);
        
        if (self.playerController.playbackState != RTSMediaPlaybackStatePlaying) {
            return;
        }
		
		// We assume that all logical segments of a full length have an identifier that is IDENTICAL to the fullLength's.
        __block id<RTSMediaSegment> currentSegment = nil;
        [self.segments enumerateObjectsUsingBlock:^(id<RTSMediaSegment> segment, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([segment.segmentIdentifier isEqualToString:self.playerController.identifier] && ![RTSMediaSegmentsController isFullLengthSegment:segment]) {
				if (CMTimeRangeContainsTime(segment.timeRange, time)) {
					currentSegment = segment;
					*stop = YES;
				}
            }
        }];
        
        if (self.lastPlaybackPositionSegment != currentSegment) {
			NSDictionary *userInfo = nil;
			
            if (!currentSegment || (self.lastPlaybackPositionSegment && currentSegment.blocked)) {
				userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentEnd),
							 RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey: self.lastPlaybackPositionSegment,
							 RTSMediaPlaybackSegmentChangeUserSelectInfoKey: @(NO)};
			}
			else if (currentSegment && !self.lastPlaybackPositionSegment && !currentSegment.blocked) {
				userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentStart),
							 RTSMediaPlaybackSegmentChangeSegmentInfoKey: currentSegment,
							 RTSMediaPlaybackSegmentChangeUserSelectInfoKey: @(NO)};
			}
			else if (currentSegment && self.lastPlaybackPositionSegment) {
				userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentSwitch),
							 RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey: self.lastPlaybackPositionSegment,
							 RTSMediaPlaybackSegmentChangeSegmentInfoKey: currentSegment,
							 RTSMediaPlaybackSegmentChangeUserSelectInfoKey: @(NO)};
			}
			
			if (userInfo) {
				[[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlaybackSegmentDidChangeNotification
																	object:self
																  userInfo:userInfo];
			}
            
			self.lastPlaybackPositionSegment = currentSegment;			
		}
		
        // Managing blocked segments
		if (currentSegment.blocked) {
            NSDictionary *userInfo = userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentSeekUponBlockingStart),
                                                  RTSMediaPlaybackSegmentChangeSegmentInfoKey: currentSegment};
            
            [[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlaybackSegmentDidChangeNotification
                                                                object:self
                                                              userInfo:userInfo];
            
            [self.playerController seekToTime:CMTimeRangeGetEnd(currentSegment.timeRange) completionHandler:^(BOOL finished) {
                NSDictionary *userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentSeekUponBlockingEnd),
                                           RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey: self.lastPlaybackPositionSegment};
                [[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlaybackSegmentDidChangeNotification
                                                                    object:self
                                                                  userInfo:userInfo];
                
                self.lastPlaybackPositionSegment = nil;
                
                [self.playerController pause];
            }];
		}
	};
	
    CMTime interval = CMTimeMakeWithSeconds(RTSMediaPlaybackTickInterval, NSEC_PER_SEC);
    self.playerTimeObserver = [self.playerController addPeriodicTimeObserverForInterval:interval
                                                                                  queue:nil
                                                                             usingBlock:checkBlock];
}

- (NSArray *)visibleSegments
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id<RTSMediaSegment>segment, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [segment isVisible];
    }];
    return [self.segments filteredArrayUsingPredicate:predicate];
}

- (id<RTSMediaSegment>)currentSegment
{
    return self.lastPlaybackPositionSegment;
}

- (void)playSegment:(id<RTSMediaSegment>)segment
{
    NSDictionary *userInfo = nil;
    if (!self.lastPlaybackPositionSegment) {
        userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentStart),
                     RTSMediaPlaybackSegmentChangeSegmentInfoKey: segment,
                     RTSMediaPlaybackSegmentChangeUserSelectInfoKey: @(YES)};
    }
    else {
        userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentSwitch),
                     RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey: self.lastPlaybackPositionSegment,
                     RTSMediaPlaybackSegmentChangeSegmentInfoKey: segment,
                     RTSMediaPlaybackSegmentChangeUserSelectInfoKey: @(YES)};
    }
    
    // Immediately send the event. We thus also update the current segment information right here
    self.lastPlaybackPositionSegment = segment;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlaybackSegmentDidChangeNotification
                                                        object:self
                                                      userInfo:userInfo];
    
    if ([self.playerController.identifier isEqualToString:segment.segmentIdentifier]) {
        [self.playerController seekToTime:segment.timeRange.start completionHandler:^(BOOL finished) {
            if (finished) {
                [self.playerController play];
            }
        }];
    }
    else {
        [self.playerController playIdentifier:segment.segmentIdentifier];
    }
}

@end

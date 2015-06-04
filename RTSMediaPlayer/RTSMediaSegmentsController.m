//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <AVFoundation/AVFoundation.h>
#import <libextobjc/EXTScope.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

#import "RTSMediaPlayerController.h"
#import "RTSMediaPlayerController+Private.h"
#import "RTSMediaPlayerSegment.h"
#import "RTSMediaSegmentsController.h"

NSTimeInterval const RTSMediaPlaybackTickInterval = 0.1;
NSString * const RTSMediaPlaybackSegmentDidChangeNotification = @"RTSMediaPlaybackSegmentDidChangeNotification";
NSString * const RTSMediaPlaybackSegmentChangeNewSegmentObjectInfoKey = @"RTSMediaPlaybackSegmentChangeNewSegmentObjectInfoKey";
NSString * const RTSMediaPlaybackSegmentChangeValueInfoKey = @"RTSMediaPlaybackSegmentChangeValueInfoKey";

@interface RTSMediaSegmentsController ()
@property(nonatomic, strong) id<RTSMediaPlayerSegment> fullLengthSegment;
@property(nonatomic, strong) NSArray *segments;
@property(nonatomic, strong) NSArray *episodes;
@property(nonatomic, strong) NSDictionary *indexMapping;
@property(nonatomic, strong) id playerTimeObserver;
@property(nonatomic, assign) NSInteger lastPlaybackPositionSegmentIndex;
@end

@implementation RTSMediaSegmentsController

- (void)reloadDataForIdentifier:(NSString *)identifier withCompletionHandler:(void (^)(void))completionHandler
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
	self.lastPlaybackPositionSegmentIndex = -1;

	RTSMediaSegmentsCompletionHandler reloadCompletionBlock = ^(id<RTSMediaPlayerSegment> fullLength, NSArray *segments, NSError *error) {
		if (error) {
			// Handle error.
			return;
		}
		
		NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"segmentTimeRange"
															 ascending:YES
															comparator:^NSComparisonResult(NSValue *timeRangeValue1, NSValue *timeRangeValue2) {
																CMTimeRange timeRange1 = [timeRangeValue1 CMTimeRangeValue];
																CMTimeRange timeRange2 = [timeRangeValue2 CMTimeRangeValue];
																return CMTimeCompare(timeRange1.start, timeRange2.start);
															}];

		self.fullLengthSegment = fullLength;
		self.segments = [segments sortedArrayUsingDescriptors:@[sd]];
		
		NSMutableArray *episodes = [NSMutableArray array];
		NSMutableIndexSet *blockedIndices = [NSMutableIndexSet indexSet];
		NSMutableDictionary *indexMapping = [NSMutableDictionary dictionary];
		
		__block NSInteger episodeIndex = -1;
		[self.segments enumerateObjectsUsingBlock:^(id<RTSMediaPlayerSegment>segment, NSUInteger idx, BOOL *stop) {
			if ([segment isBlocked] == NO) {
				[blockedIndices addIndex:idx];
			}
			if ([segment isVisible]) {
				episodeIndex ++;
				[indexMapping setObject:@(episodeIndex) forKey:@(idx)];
				[episodes addObject:segment];
			}
			else {
				[indexMapping setObject:@(NSNotFound) forKey:@(idx)];
			}
		}];
		
		self.episodes = [NSArray arrayWithArray:episodes]; // Ensure there is always an array, even if it is empty.
		self.indexMapping = [indexMapping copy];
		
		NSAssert(self.indexMapping.count == self.segments.count,
				 @"One must have the same number of index for mapping as we have segments.");
		
		[self addBlockingTimeObserver];
		
		if (completionHandler) {
			completionHandler();
		}
	};
	
	[self.dataSource segmentsController:self segmentsForIdentifier:identifier withCompletionHandler:reloadCompletionBlock];
}

- (void)removeBlockingTimeObserver
{
	if (self.playerController && self.playerTimeObserver) {
		[self.playerController removePlaybackTimeObserver:self.playerTimeObserver];
		self.playerTimeObserver = nil;
	}
}

- (void)addBlockingTimeObserver
{
	@weakify(self);
	void (^checkBlock)(CMTime) = ^(CMTime time) {
		@strongify(self);
		NSUInteger secondaryIndex;
		NSUInteger index = [self indexOfSegmentForTime:time secondaryIndex:&secondaryIndex];
		
		DDLogDebug(@"Playing time %.2fs at index %ld", CMTimeGetSeconds(time), index);
		
		if (self.playerController.playbackState == RTSMediaPlaybackStatePlaying && [self isTimeBlocked:time]) {
			dispatch_async(dispatch_get_main_queue(), ^{
				NSDictionary *userInfo = userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentSeekUponBlocking)};
				[[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlaybackSegmentDidChangeNotification
																	object:self
																  userInfo:userInfo];
			});

			// The reason for blocking must be specified, and should actually be accessile from the segment object, IMHO.
			[self.playerController fireSeekEventWithUserInfo:@{RTSMediaPlayerPlaybackSeekingUponBlockingReasonInfoKey: @"blocked"}];
			[self seekToNextAvailableSegmentAfterIndex:index];
		}
		else {
			if (self.lastPlaybackPositionSegmentIndex != index) {
				NSDictionary *userInfo = nil;
				if (index == NSNotFound) {
					userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentEnd)};
				}
				else if (index != NSNotFound && self.lastPlaybackPositionSegmentIndex == NSNotFound) {
					userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentEnd),
								 RTSMediaPlaybackSegmentChangeNewSegmentObjectInfoKey: self.segments[index]};
				}
				else if (index != NSNotFound && self.lastPlaybackPositionSegmentIndex == NSNotFound) {
					userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentSwitch),
								 RTSMediaPlaybackSegmentChangeNewSegmentObjectInfoKey: self.segments[index]};
				}
				
				dispatch_async(dispatch_get_main_queue(), ^{
					[[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlaybackSegmentDidChangeNotification
																		object:self
																	  userInfo:userInfo];
				});
			}
			
			self.lastPlaybackPositionSegmentIndex = index;
		}
	};
	
	CMTime interval = CMTimeMakeWithSeconds(RTSMediaPlaybackTickInterval, NSEC_PER_SEC);
	self.playerTimeObserver = [self.playerController addPlaybackTimeObserverForInterval:interval
																				  queue:nil
																			 usingBlock:checkBlock];
}

- (void)seekToNextAvailableSegmentAfterIndex:(NSInteger)index
{
	NSUInteger nextIndex = [self indexOfLastContiguousBlockedSegmentAfterIndex:index
															withFlexibilityGap:RTSMediaPlaybackTickInterval];
	
	// nextIndex can be equal to index (it happens when after segment@index, there is playback outside any segment.
	// Hence, if we get a nextIndex, one must seek to the end of it + a small bit.
		
	if (nextIndex == NSUIntegerMax) {
		CMTimeRange r = self.fullLengthSegment.segmentTimeRange;
		[self.playerController.player seekToTime:CMTimeAdd(r.start, r.duration)];
	}
	else {
		id<RTSMediaPlayerSegment> segment = self.segments[nextIndex];
		CMTime oneInterval = CMTimeMakeWithSeconds(RTSMediaPlaybackTickInterval, NSEC_PER_SEC);
		CMTimeRange r = segment.segmentTimeRange;
		CMTime seekCMTime = CMTimeAdd(r.start, CMTimeAdd(r.duration, oneInterval));
		
		[self.playerController.player seekToTime:seekCMTime
								 toleranceBefore:kCMTimeZero
								  toleranceAfter:kCMTimeZero
							   completionHandler:^(BOOL finished) {
								   if (finished) {
									   [self.playerController pause];
								   }
							   }];
	}
}

- (BOOL)isTimeBlocked:(CMTime)time
{
	NSUInteger secondaryIndex;
	NSUInteger index = [self indexOfSegmentForTime:time secondaryIndex:&secondaryIndex];
	return [self isSegmentBlockedAtIndex:index] && [self isSegmentBlockedAtIndex:secondaryIndex];
}

- (NSUInteger)indexOfSegmentForTime:(CMTime)time secondaryIndex:(NSUInteger *)secondaryIndex
{
	CMTime auxTime = CMTimeAdd(time, CMTimeMakeWithSeconds(RTSMediaPlaybackTickInterval, NSEC_PER_SEC));
	
	// For small number of segments (say, < 64), a range tree algorithm wouldn't be more efficient.
	// See for instance https://github.com/heardrwt/RHIntervalTree
	
	__block NSUInteger result = NSNotFound;
	__block NSUInteger secondaryResult = NSNotFound;
	
	[self.segments enumerateObjectsUsingBlock:^(id<RTSMediaPlayerSegment> segment, NSUInteger idx, BOOL *stop) {
		if (CMTimeRangeContainsTime(segment.segmentTimeRange, time)) {
			result = idx;
		}
		if (CMTimeRangeContainsTime(segment.segmentTimeRange, auxTime)) {
			secondaryResult = idx;
		}
		if (result != NSNotFound && secondaryResult != NSNotFound) {
			*stop = YES;
		}
	}];
	
	if (secondaryIndex != NULL) {
		*secondaryIndex = secondaryResult;
	}
	
	return result;
}

- (NSUInteger)countOfSegments
{
    return self.segments.count;
}

- (NSUInteger)countOfVisibleSegments
{
    return self.episodes.count;
}

- (NSArray *)visibleSegments
{
    return [NSArray arrayWithArray:self.episodes];
}

- (NSUInteger)indexOfVisibleSegmentForSegmentIndex:(NSUInteger)segmentIndex
{
    if (segmentIndex == NSNotFound || self.segments.count == 0) {
        return NSNotFound;
    }
    return [[self.indexMapping objectForKey:@(segmentIndex)] unsignedIntegerValue];
}

- (BOOL)isSegmentBlockedAtIndex:(NSUInteger)index
{
    if (index < self.segments.count) {
        return [self.segments[index] isBlocked];
    }
    return NO;
}

- (BOOL)isVisibleSegmentBlockedAtIndex:(NSUInteger)index
{
	if (index < self.visibleSegments.count) {
		return [self.visibleSegments[index] isBlocked];
	}
	return NO;
}


- (NSUInteger)indexOfLastContiguousBlockedSegmentAfterIndex:(NSUInteger)index withFlexibilityGap:(NSTimeInterval)flexibilityGap
{
    if (self.segments.count == 0 || index == NSNotFound || index >= self.segments.count) {
        return NSNotFound;
    }
    
    id<RTSMediaPlayerSegment> inputSegment = self.segments[index];
	CMTimeRange r = inputSegment.segmentTimeRange;
    NSTimeInterval inputSegmentEndTime = (NSTimeInterval) CMTimeGetSeconds(r.start) + CMTimeGetSeconds(r.duration);

    if (index+1 >= self.segments.count) {
        // Ok, we have no additional segments  See if there is some time left at end of full length media.
		
		CMTimeRange r = self.fullLengthSegment.segmentTimeRange;
        NSTimeInterval fullLengthEndTime = (NSTimeInterval) CMTimeGetSeconds(r.start) + CMTimeGetSeconds(r.duration);
        NSTimeInterval mediaLastSeconds = fullLengthEndTime - inputSegmentEndTime;
        
        if (mediaLastSeconds < 2*flexibilityGap) {
            // There is no meaningful playable content after the end of the current segment.
            return NSUIntegerMax;
        }
        else {
            // There is some meaningful playable content after the end of the current segment. But no more segment afterwards.
            // Hence restart playing from the end of the current index.
            return index;
        }
    }
    
    NSUInteger result = index;
    for (NSUInteger i = index+1; i < self.segments.count; i++) {
        id<RTSMediaPlayerSegment> segment = self.segments[i];
        if (![segment isBlocked]) {
            // Next segment is not blocked. Hence the end of the current one is the last we are look for.
            break;
        }
        
        NSTimeInterval gap = (NSTimeInterval) CMTimeGetSeconds(segment.segmentTimeRange.start) - inputSegmentEndTime;
        if (gap > 2*flexibilityGap) {
            // Gap is larger than threshold, hence valid, hence playable.
            break;
        }
        
        // Gap is smaller than threshold, and next segment is blocked. Hence pursue the 'for loop'.
        result = i;
    }
    
    return result;
}

- (NSInteger)currentVisibleSegmentIndex
{
	NSUInteger currentSegment = [self indexOfSegmentForTime:self.playerController.player.currentTime secondaryIndex:NULL];
	if (currentSegment == NSNotFound) {
		return -1;
	}
	NSUInteger currentVisibleSegment = [self indexOfVisibleSegmentForSegmentIndex:currentSegment];
	if (currentVisibleSegment == NSNotFound) {
		return -1;
	}
	return (NSInteger)currentVisibleSegment;
}

- (NSInteger)currentSegmentIndex
{
	NSUInteger currentSegment = [self indexOfSegmentForTime:self.playerController.player.currentTime secondaryIndex:NULL];
	if (currentSegment == NSNotFound) {
		return -1;
	}
	return (NSInteger)currentSegment;
}

#pragma mark - RTSMediaPlayback

- (void)prepareToPlay
{
	[self.playerController prepareToPlay];
}

- (void)play
{
	[self.playerController pause];
}

- (void)playIdentifier:(NSString *)identifier
{
	[self.playerController playIdentifier:identifier];
}

- (void)pause
{
	[self.playerController pause];
}

- (void)reset
{
	[self.playerController reset];
}

- (void)mute:(BOOL)flag
{
	[self.playerController mute:flag];
}

- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL))completionHandler
{
	if (![self isTimeBlocked:time]) {
		[self.playerController seekToTime:time completionHandler:completionHandler];
	}
}

- (AVPlayerItem *)playerItem
{
	return [self.playerController playerItem];
}

- (id)addPlaybackTimeObserverForInterval:(CMTime)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(CMTime))block
{
	return [self.playerController addPlaybackTimeObserverForInterval:interval queue:queue usingBlock:block];
}

- (void)removePlaybackTimeObserver:(id)observer
{
	return [self.playerController removePlaybackTimeObserver:observer];
}

@end

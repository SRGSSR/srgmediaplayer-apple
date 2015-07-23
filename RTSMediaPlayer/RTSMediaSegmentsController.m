//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <AVFoundation/AVFoundation.h>
#import <libextobjc/EXTScope.h>

#import "RTSMediaPlayerController.h"
#import "RTSMediaSegment.h"
#import "RTSMediaSegmentsController.h"
#import "RTSMediaPlayerLogger.h"

NSTimeInterval const RTSMediaPlaybackTickInterval = 0.1;
NSString * const RTSMediaPlaybackSegmentDidChangeNotification = @"RTSMediaPlaybackSegmentDidChangeNotification";
NSString * const RTSMediaPlaybackSegmentChangeSegmentInfoKey = @"RTSMediaPlaybackSegmentChangeSegmentInfoKey";
NSString * const RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey = @"RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey";
NSString * const RTSMediaPlaybackSegmentChangeValueInfoKey = @"RTSMediaPlaybackSegmentChangeValueInfoKey";
NSString * const RTSMediaPlaybackSegmentChangeUserSelectInfoKey = @"RTSMediaPlaybackSegmentChangeUserSelectInfoKey";

@interface RTSMediaSegmentsController ()
@property(nonatomic, strong) id<RTSMediaSegment> fullLengthSegment;
@property(nonatomic, strong) NSArray *segments;
@property(nonatomic, strong) NSArray *episodes;
@property(nonatomic, strong) NSDictionary *indexMapping;
@property(nonatomic, strong) id playerTimeObserver;
@property(nonatomic, assign) NSUInteger lastPlaybackPositionSegmentIndex;
@end

@implementation RTSMediaSegmentsController

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
	self.lastPlaybackPositionSegmentIndex = NSNotFound;

	RTSMediaSegmentsCompletionHandler reloadCompletionBlock = ^(id<RTSMediaSegment> fullLength, NSArray *segments, NSError *error) {
		if (error) {
			if (completionHandler) {
				completionHandler(error);
			}
			return;
		}
		
		NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"timeRange"
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
		[self.segments enumerateObjectsUsingBlock:^(id<RTSMediaSegment>segment, NSUInteger idx, BOOL *stop) {
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
		if (self.playerController.playbackState != RTSMediaPlaybackStatePlaying) {
			return;
		}
		
		@strongify(self);
		NSUInteger secondaryIndex;
		NSUInteger index = [self indexOfSegmentForTime:time secondaryIndex:&secondaryIndex];
		BOOL isTimeBlocked = [self isTimeBlocked:time];
		
		RTSMediaPlayerLogDebug(@"Playing %@ time %.2fs at index %@ (secondary: %@, last: %@)", (isTimeBlocked)? @"blocked" : @"",
			  CMTimeGetSeconds(time), @(index), @(secondaryIndex), @(self.lastPlaybackPositionSegmentIndex));
		
		if (self.lastPlaybackPositionSegmentIndex != index) {
			NSDictionary *userInfo = nil;
			
			if (index == NSNotFound || (self.lastPlaybackPositionSegmentIndex != NSNotFound && isTimeBlocked)) {
				RTSMediaPlayerLogDebug(@"Sending Segment End notification. Time Blocked: %@. Previous segment index: %@ (was selected: NO)",
									   @(isTimeBlocked), @(self.lastPlaybackPositionSegmentIndex));
				
				userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentEnd),
							 RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey: self.segments[self.lastPlaybackPositionSegmentIndex],
							 RTSMediaPlaybackSegmentChangeUserSelectInfoKey: @NO};
			}
			else if (index != NSNotFound && self.lastPlaybackPositionSegmentIndex == NSNotFound && !isTimeBlocked) {
				RTSMediaPlayerLogDebug(@"Sending Segment Start notification. Segment index: %@ (was selected: NO)",
									   @(index));
				
				userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentStart),
							 RTSMediaPlaybackSegmentChangeSegmentInfoKey: self.segments[index],
							 RTSMediaPlaybackSegmentChangeUserSelectInfoKey: @NO};
			}
			else if (index != NSNotFound && self.lastPlaybackPositionSegmentIndex != NSNotFound) {
				RTSMediaPlayerLogDebug(@"Sending Segment Switch notification. Segment index: %@ (was selected: NO), previous: %@",
									   @(index), @(self.lastPlaybackPositionSegmentIndex));
				
				userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentSwitch),
							 RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey: self.segments[self.lastPlaybackPositionSegmentIndex],
							 RTSMediaPlaybackSegmentChangeSegmentInfoKey: self.segments[index],
							 RTSMediaPlaybackSegmentChangeUserSelectInfoKey: @NO};
			}
			
			// Immediatly reseting the property after it has been used.
			self.lastPlaybackPositionSegmentIndex = index;
			
			[[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlaybackSegmentDidChangeNotification
																object:self
															  userInfo:userInfo];
		}
		
		if (isTimeBlocked) {
			// The reason for blocking must be specified, and should actually be accessible from the segment object, IMHO.
			
			RTSMediaPlayerLogDebug(@"Sending SeekUponBlocking Start notification. Segment index: %@", @(index));
			
			NSDictionary *userInfo = userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentSeekUponBlockingStart),
												  RTSMediaPlaybackSegmentChangeSegmentInfoKey: self.segments[index]};

			[[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlaybackSegmentDidChangeNotification
																object:self
															  userInfo:userInfo];
		
			[self seekToNextAvailableSegmentAfterIndex:index];
		}
	};
	
	CMTime interval = CMTimeMakeWithSeconds(RTSMediaPlaybackTickInterval, NSEC_PER_SEC);
	self.playerTimeObserver = [self.playerController addPeriodicTimeObserverForInterval:interval
																				  queue:nil
																			 usingBlock:checkBlock];
}

- (void)seekToNextAvailableSegmentAfterIndex:(NSInteger)index
{
	NSInteger nextIndex = [self indexOfLastContiguousBlockedSegmentAfterIndex:index
														   withFlexibilityGap:RTSMediaPlaybackTickInterval];
	
	// nextIndex can be equal to index (it happens when after segment@index, there is playback outside any segment.
	// Hence, if we get a nextIndex, one must seek to the end of it + a small bit.
	
	void (^completionBlock)(BOOL) = ^(BOOL finished) {
		if (finished) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.playerController pause]; // Will put the player into the pause state.
				NSDictionary *userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentSeekUponBlockingEnd),
										   RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey: self.segments[index] };
				[[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlaybackSegmentDidChangeNotification
																	object:self
																  userInfo:userInfo];
			});
		}
	};
	
	if (nextIndex == -1) {
		CMTimeRange r = self.fullLengthSegment.timeRange;
		[self.playerController seekToTime:CMTimeAdd(r.start, r.duration) completionHandler:completionBlock];
	}
	else if (nextIndex >= 0) {
		NSAssert(nextIndex < self.segments.count, @"Wrong index.");
		id<RTSMediaSegment> segment = self.segments[nextIndex];
		CMTime oneInterval = CMTimeMakeWithSeconds(RTSMediaPlaybackTickInterval, NSEC_PER_SEC);
		CMTimeRange r = segment.timeRange;
		
		CMTime seekCMTime = CMTimeAdd(r.start, CMTimeAdd(r.duration, oneInterval));
		[self.playerController seekToTime:seekCMTime completionHandler:completionBlock];
	}
}

- (BOOL)isTimeBlocked:(CMTime)time
{
	NSUInteger secondaryIndex;
	NSUInteger index = [self indexOfSegmentForTime:time secondaryIndex:&secondaryIndex];
	return [self isSegmentBlockedAtIndex:index] && [self isSegmentBlockedAtIndex:secondaryIndex];
}

- (NSUInteger)indexOfVisibleSegmentForTime:(CMTime)time
{
	NSUInteger index = [self indexOfSegmentForTime:time secondaryIndex:NULL];
	return [self indexOfVisibleSegmentForSegmentIndex:index];
}

- (NSUInteger)indexOfSegmentForTime:(CMTime)time secondaryIndex:(NSUInteger *)secondaryIndex
{
	CMTime auxTime = CMTimeAdd(time, CMTimeMakeWithSeconds(RTSMediaPlaybackTickInterval, NSEC_PER_SEC));
	
	// For small number of segments (say, < 64), a range tree algorithm wouldn't be more efficient.
	// See for instance https://github.com/heardrwt/RHIntervalTree
	
	__block NSUInteger result = NSNotFound;
	__block NSUInteger secondaryResult = NSNotFound;
	
	[self.segments enumerateObjectsUsingBlock:^(id<RTSMediaSegment> segment, NSUInteger idx, BOOL *stop) {
		if (CMTimeRangeContainsTime(segment.timeRange, time)) {
			result = idx;
		}
		if (CMTimeRangeContainsTime(segment.timeRange, auxTime)) {
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


- (NSInteger)indexOfLastContiguousBlockedSegmentAfterIndex:(NSUInteger)index withFlexibilityGap:(NSTimeInterval)flexibilityGap
{
    if (self.segments.count == 0 || index == NSNotFound || index >= self.segments.count) {
        return NSNotFound;
    }
    
    id<RTSMediaSegment> inputSegment = self.segments[index];
	CMTimeRange r = inputSegment.timeRange;
    NSTimeInterval inputSegmentEndTime = (NSTimeInterval) CMTimeGetSeconds(r.start) + CMTimeGetSeconds(r.duration);

    if (index+1 >= self.segments.count) {
        // Ok, we have no additional segments  See if there is some time left at end of full length media.
		
		CMTimeRange r = self.fullLengthSegment.timeRange;
        NSTimeInterval fullLengthEndTime = (NSTimeInterval) CMTimeGetSeconds(r.start) + CMTimeGetSeconds(r.duration);
        NSTimeInterval mediaLastSeconds = fullLengthEndTime - inputSegmentEndTime;
        
        if (mediaLastSeconds < 2*flexibilityGap) {
            // There is no meaningful playable content after the end of the current segment.
            return -1;
        }
        else {
            // There is some meaningful playable content after the end of the current segment. But no more segment afterwards.
            // Hence restart playing from the end of the current index.
            return index;
        }
    }
    
    NSInteger result = index;
    for (NSInteger i = index+1; i < self.segments.count; i++) {
        id<RTSMediaSegment> segment = self.segments[i];
        if (![segment isBlocked]) {
            // Next segment is not blocked. Hence the end of the current one is the last we are look for.
            break;
        }
        
        NSTimeInterval gap = (NSTimeInterval) CMTimeGetSeconds(segment.timeRange.start) - inputSegmentEndTime;
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

- (void)playVisibleSegmentAtIndex:(NSUInteger)index
{
	if (index >= self.visibleSegments.count) {
		return;
	}
	
	id<RTSMediaSegment> segment = self.visibleSegments[index];
	if (segment.isBlocked) {
		return;
	}
	
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
	userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] = @(RTSMediaPlaybackSegmentStart);
	userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey] = segment;
	userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] = @YES;

	if (self.lastPlaybackPositionSegmentIndex != NSNotFound) {
		userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey] = self.segments[self.lastPlaybackPositionSegmentIndex];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlaybackSegmentDidChangeNotification
														object:self
													  userInfo:[userInfo copy]];
	
	self.lastPlaybackPositionSegmentIndex = index;
	
	[self.playerController seekToTime:segment.timeRange.start completionHandler:^(BOOL finished) {
		if (finished) {
			[self.playerController play];
		}
	}];
}


#pragma mark - RTSMediaPlayback

- (void)prepareToPlay
{
	[self.playerController prepareToPlay];
}

- (void)play
{
	[self.playerController play];
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

- (BOOL)isMuted
{
	return [self.playerController isMuted];
}

- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL))completionHandler
{
	if (![self isTimeBlocked:time]) {
		[self.playerController seekToTime:time completionHandler:completionHandler];
	}
}

- (void)playAtTime:(CMTime)time
{
	if (self.playerController.playbackState == RTSMediaPlaybackStateSeeking && [self isTimeBlocked:time]) {
		
		NSInteger index = [self indexOfSegmentForTime:time secondaryIndex:NULL];
		
		NSDictionary *userInfo = userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentSeekUponBlockingStart),
											  RTSMediaPlaybackSegmentChangeSegmentInfoKey: self.segments[index]};
		
		[[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlaybackSegmentDidChangeNotification
															object:self
														  userInfo:userInfo];
		
		[self seekToNextAvailableSegmentAfterIndex:index];
		
		return;
	}

	[self.playerController playAtTime:time];
}

- (AVPlayerItem *)playerItem
{
	return [self.playerController playerItem];
}

- (CMTimeRange)timeRange
{
	return self.playerController.timeRange;
}

- (RTSMediaType)mediaType
{
	return self.playerController.mediaType;
}

- (RTSMediaStreamType)streamType
{
	return self.playerController.streamType;
}

- (id)addPeriodicTimeObserverForInterval:(CMTime)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(CMTime))block
{
	return [self.playerController addPeriodicTimeObserverForInterval:interval queue:queue usingBlock:block];
}

- (void)removePeriodicTimeObserver:(id)observer
{
	return [self.playerController removePeriodicTimeObserver:observer];
}

@end

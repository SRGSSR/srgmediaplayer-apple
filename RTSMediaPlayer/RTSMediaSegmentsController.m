//
//  RTSMediaSegmentsController.m
//  RTSMediaPlayer
//
//  Created by Cédric Foellmi on 27/05/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "RTSMediaSegmentsController.h"
#import "RTSMediaPlayerSegmentDataSource.h"
#import "RTSMediaPlayerSegment.h"

@interface RTSMediaSegmentsController ()
@property(nonatomic, strong) id<RTSMediaPlayerSegment> fullLengthSegment;
@property(nonatomic, strong) NSArray *segments;
@property(nonatomic, strong) NSArray *episodes;
@property(nonatomic, strong) NSDictionary *indexMapping;
@end

@implementation RTSMediaSegmentsController

- (void)reloadDataForIdentifier:(NSString *)identifier onCompletion:(void (^)(void))completionBlock
{
	NSParameterAssert(identifier);
	
	if (!self.dataSource) {
		self.segments = [NSArray new];
	}

	[self.dataSource segmentsController:self
				  segmentsForIdentifier:identifier
						   onCompletion:^(id<RTSMediaPlayerSegment> fullLength, NSArray *segments, NSError *error) {
							  if (error) {
								  // Handle error.
								  return;
							  }
							  
							  NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"segmentTimeRange" ascending:YES comparator:^NSComparisonResult(NSValue *timeRangeValue1, NSValue *timeRangeValue2) {
								  CMTimeRange timeRange1 = [timeRangeValue1 CMTimeRangeValue];
								  CMTimeRange timeRange2 = [timeRangeValue2 CMTimeRangeValue];
								  return CMTimeCompare(timeRange1.start, timeRange2.start);
							  }];

							  self.fullLengthSegment = fullLength;
							  self.segments = [segments sortedArrayUsingDescriptors:@[sortDescriptor]];
							  
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
							  
							  if (completionBlock) {
								  completionBlock();
							  }
						  }];
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

- (NSUInteger)visibleSegmentIndexForSegmentIndex:(NSUInteger)segmentIndex
{
    if (segmentIndex == NSNotFound || self.segments.count == 0) {
        return NSNotFound;
    }
    return [[self.indexMapping objectForKey:@(segmentIndex)] unsignedIntegerValue];
}

- (BOOL)isSegmentBlockedAtIndex:(NSInteger)index
{
    if (index >= 0 && index < self.segments.count) {
        return [self.segments[index] isBlocked];
    }
    return NO;
}

- (NSInteger)indexOfLastContiguousBlockedSegmentAfterIndex:(NSInteger)index withFlexibilityGap:(CGFloat)flexibilityGap
{
    if (self.segments.count == 0 || index == NSNotFound || index >= self.segments.count) {
        return NSNotFound;
    }
    
    id<RTSMediaPlayerSegment> inputSegment = self.segments[index];
    NSTimeInterval inputSegmentEndTime = (NSTimeInterval) CMTimeGetSeconds(inputSegment.segmentTimeRange.start)+CMTimeGetSeconds(inputSegment.segmentTimeRange.duration);

    if (index+1 >= self.segments.count) {
        // Ok, we have no additional segments  See if there is some time left at end of full length media.
        
        NSTimeInterval fullLengthEndTime = (NSTimeInterval) CMTimeGetSeconds(self.fullLengthSegment.segmentTimeRange.start)+CMTimeGetSeconds(self.fullLengthSegment.segmentTimeRange.duration);
        NSTimeInterval mediaLastSeconds = fullLengthEndTime - inputSegmentEndTime;
        
        if (mediaLastSeconds < 2*flexibilityGap) {
            // There is no meaningful playable content after the end of the current segment.
            return NSNotFound;
        }
        else {
            // There is some meaningful playable content after the end of the current segment. But no more segment afterwards.
            // Hence restart playing from the end of the current index.
            return index;
        }
    }
    
    NSInteger result = index;
    for (NSInteger i = index+1; i < self.segments.count; i++) {
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

@end

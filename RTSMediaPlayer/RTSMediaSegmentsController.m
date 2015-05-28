//
//  RTSMediaSegmentsController.m
//  RTSMediaPlayer
//
//  Created by Cédric Foellmi on 27/05/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSMediaSegmentsController.h"

@interface RTSMediaSegmentsController () {
    RTSMediaPlayerController *_playerController;
    id<RTSMediaPlayerSegment> _media;
    NSArray *_segments;
    NSArray *_episodes;
    NSDictionary *_indexMapping;
}
@end

@implementation RTSMediaSegmentsController

- (instancetype)initWithPlayerController:(RTSMediaPlayerController *)playerController
                          fullLenghMedia:(id<RTSMediaPlayerSegment>)media
                                segments:(NSArray<RTSMediaPlayerSegment> *)segments
{
    NSParameterAssert(playerController && media && segments);
    
    self = [super init];
    if (self) {
        _playerController = playerController;
        _media = media;
        _segments = segments;
        
        NSMutableArray *episodes = [NSMutableArray array];
        NSMutableIndexSet *blockedIndices = [NSMutableIndexSet indexSet];
        NSMutableDictionary *indexMapping = [NSMutableDictionary dictionary];
        
        __block NSInteger episodeIndex = -1;
        [_segments enumerateObjectsUsingBlock:^(id<RTSMediaPlayerSegment>segment, NSUInteger idx, BOOL *stop) {
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
        
        _episodes = [NSArray arrayWithArray:episodes]; // Ensure there is always an array, even if it is empty.
        _indexMapping = [indexMapping copy];
        
        NSAssert(_indexMapping.count == _segments.count,
                 @"One must have the same number of index for mapping as we have segments.");
    }
    return self;
}

- (NSUInteger)countOfSegments
{
    return _segments.count;
}

- (NSArray *)segments
{
    return [NSArray arrayWithArray:_segments];
}

- (NSUInteger)countOfVisibleSegments
{
    return _episodes.count;
}

- (NSArray *)visibleSegments
{
    return [NSArray arrayWithArray:_episodes];
}

- (NSUInteger)visibleSegmentIndexForSegmentIndex:(NSUInteger)segmentIndex
{
    if (segmentIndex == NSNotFound || _segments.count == 0) {
        return NSNotFound;
    }
    return [[_indexMapping objectForKey:@(segmentIndex)] unsignedIntegerValue];
}

- (BOOL)isSegmentBlockedAtIndex:(NSInteger)index
{
    if (index >= 0 && index < _segments.count) {
        return [_segments[index] isBlocked];
    }
    return NO;
}

- (NSInteger)indexOfLastContiguousBlockedSegmentAfterIndex:(NSInteger)index withFlexibilityGap:(CGFloat)flexibilityGap
{
    if (_segments.count == 0 || index == NSNotFound || index >= _segments.count) {
        return NSNotFound;
    }
    
    id<RTSMediaPlayerSegment> inputSegment = _segments[index];
    NSTimeInterval inputSegmentEndTime = (NSTimeInterval) CMTimeGetSeconds(inputSegment.segmentTimeRange.start)+CMTimeGetSeconds(inputSegment.segmentTimeRange.duration);

    if (index+1 >= _segments.count) {
        // Ok, we have no additional segments  See if there is some time left at end of full length media.
        
        NSTimeInterval fullLengthEndTime = (NSTimeInterval) CMTimeGetSeconds(_media.segmentTimeRange.start)+CMTimeGetSeconds(_media.segmentTimeRange.duration);
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
    for (NSInteger i = index+1; i < _segments.count; i++) {
        id<RTSMediaPlayerSegment> segment = _segments[i];
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

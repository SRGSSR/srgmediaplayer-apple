//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <XCTest/XCTest.h>

#import "Segment.h"

@interface RTSMediaSegmentsTestCase : XCTestCase
@end

@implementation RTSMediaSegmentsTestCase

#pragma mark - Tests

// Expect segment start / end notifications
- (void)testSegmentPlaythrough
{
    
}

// Expect seek notifications skipping the segment
- (void)testBlockedSegmentPlaythrough
{
    
}

// Expect segment start / end notifications
- (void)testSegmentAtStartPlaythrough
{
}

// Expect seek notifications skipping the segment
- (void)testBlockedSegmentAtStartPlaythrough
{
    
}

// Expect segment end and start notifications
- (void)testConsecutiveSegments
{
    
}

// Expect two skips, one for the first segment, another one for the second one
- (void)testContiguousBlockedSegments
{

}

// Expect two skips, one for the first segment, another one for the second one
- (void)testContiguousBlockedSegmentsAtStart
{
    
}

// Expect single seek for the first segment. Playback resumes where no blocking takes place, but no events for the second
// segment are received
- (void)testSegmentTransitionIntoBlockedSegment
{

}

// Expect a start event for the given segment, with YES for the user-driven information flag
- (void)testProgrammaticSegmentPlay
{

}

// Expect a seek
- (void)testProgrammaticBlockedSegmentPlay
{
    
}

// Expect a start event for the given segment, with NO for the user-driven information flag (set only when calling -playSegment:)
- (void)testSeekIntoSegment
{

}

- (void)testSeekIntoBlockedSegment
{

}

// Expect a switch between the two segments
- (void)testUserTriggeredSegmentPlayAfterUserTriggeredSegmentPlay
{

}

@end

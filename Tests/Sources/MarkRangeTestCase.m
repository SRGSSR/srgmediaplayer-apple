//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaPlayerBaseTestCase.h"
#import "TestMacros.h"

#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface MarkRangeTestCase : MediaPlayerBaseTestCase

@end

@implementation MarkRangeTestCase

#pragma mark Tests

- (void)testCreation
{
    SRGMark *fromMark = [SRGMark markAtTimeInSeconds:5.];
    SRGMark *toMark = [SRGMark markAtTimeInSeconds:10.];
    SRGMarkRange *markRange = [SRGMarkRange rangeFromMark:fromMark toMark:toMark];
    XCTAssertEqualObjects(markRange.fromMark, fromMark);
    XCTAssertEqualObjects(markRange.toMark, toMark);
}

- (void)testCreationFromTimes
{
    SRGMarkRange *markRange = [SRGMarkRange rangeFromTime:CMTimeMakeWithSeconds(5., NSEC_PER_SEC) toTime:CMTimeMakeWithSeconds(10., NSEC_PER_SEC)];
    XCTAssertEqualObjects(markRange.fromMark, [SRGMark markAtTimeInSeconds:5.]);
    XCTAssertEqualObjects(markRange.toMark, [SRGMark markAtTimeInSeconds:10.]);
}

- (void)testCreationFromTimesInSeconds
{
    SRGMarkRange *markRange = [SRGMarkRange rangeFromTimeInSeconds:5. toTimeInSeconds:10.];
    XCTAssertEqualObjects(markRange.fromMark, [SRGMark markAtTime:CMTimeMakeWithSeconds(5., NSEC_PER_SEC)]);
    XCTAssertEqualObjects(markRange.toMark, [SRGMark markAtTime:CMTimeMakeWithSeconds(10., NSEC_PER_SEC)]);
}

- (void)testCreationFromTimeRange
{
    SRGMarkRange *markRange = [SRGMarkRange rangeFromTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(5., NSEC_PER_SEC), CMTimeMakeWithSeconds(7., NSEC_PER_SEC))];
    XCTAssertEqualObjects(markRange.fromMark, [SRGMark markAtTimeInSeconds:5.]);
    XCTAssertEqualObjects(markRange.toMark, [SRGMark markAtTimeInSeconds:12.]);
}

- (void)testCreationFromDates
{
    NSDate *date1 = NSDate.date;
    NSDate *date2 = [date1 dateByAddingTimeInterval:10.];
    
    SRGMarkRange *markRange = [SRGMarkRange rangeFromDate:date1 toDate:date2];
    XCTAssertEqualObjects(markRange.fromMark, [SRGMark markAtDate:date1]);
    XCTAssertEqualObjects(markRange.toMark, [SRGMark markAtDate:date2]);
}

- (void)testEquality
{
    SRGMarkRange *timeMarkRange1 = [SRGMarkRange rangeFromTimeInSeconds:5. toTimeInSeconds:10.];
    SRGMarkRange *timeMarkRange2 = [SRGMarkRange rangeFromTimeInSeconds:5. toTimeInSeconds:10.];
    SRGMarkRange *timeMarkRange3 = [SRGMarkRange rangeFromTimeInSeconds:7. toTimeInSeconds:10.];
    SRGMarkRange *timeMarkRange4 = [SRGMarkRange rangeFromTimeInSeconds:5. toTimeInSeconds:12.];
    SRGMarkRange *timeMarkRange5 = [SRGMarkRange rangeFromTimeInSeconds:7. toTimeInSeconds:12.];
    
    NSDate *date = NSDate.date;
    SRGMarkRange *dateMarkRange1 = [SRGMarkRange rangeFromDate:date toDate:[date dateByAddingTimeInterval:10.]];
    SRGMarkRange *dateMarkRange2 = [SRGMarkRange rangeFromDate:date toDate:[date dateByAddingTimeInterval:10.]];
    SRGMarkRange *dateMarkRange3 = [SRGMarkRange rangeFromDate:[date dateByAddingTimeInterval:2.] toDate:[date dateByAddingTimeInterval:10.]];
    SRGMarkRange *dateMarkRange4 = [SRGMarkRange rangeFromDate:date toDate:[NSDate dateWithTimeIntervalSinceNow:12.]];
    SRGMarkRange *dateMarkRange5 = [SRGMarkRange rangeFromDate:[date dateByAddingTimeInterval:2.] toDate:[date dateByAddingTimeInterval:10.]];
    
    XCTAssertEqualObjects(timeMarkRange1, timeMarkRange1);
    XCTAssertEqualObjects(timeMarkRange1, timeMarkRange2);
    XCTAssertNotEqualObjects(timeMarkRange1, timeMarkRange3);
    XCTAssertNotEqualObjects(timeMarkRange1, timeMarkRange4);
    XCTAssertNotEqualObjects(timeMarkRange1, timeMarkRange5);
    XCTAssertNotEqualObjects(timeMarkRange1, dateMarkRange1);
    XCTAssertNotEqualObjects(timeMarkRange1, dateMarkRange2);
    XCTAssertNotEqualObjects(timeMarkRange1, dateMarkRange3);
    XCTAssertNotEqualObjects(timeMarkRange1, dateMarkRange4);
    XCTAssertNotEqualObjects(timeMarkRange1, dateMarkRange5);
    
    XCTAssertEqualObjects(dateMarkRange1, dateMarkRange1);
    XCTAssertEqualObjects(dateMarkRange1, dateMarkRange2);
    XCTAssertNotEqualObjects(dateMarkRange1, dateMarkRange3);
    XCTAssertNotEqualObjects(dateMarkRange1, dateMarkRange4);
    XCTAssertNotEqualObjects(dateMarkRange1, dateMarkRange5);
    XCTAssertNotEqualObjects(dateMarkRange1, timeMarkRange1);
    XCTAssertNotEqualObjects(dateMarkRange1, timeMarkRange2);
    XCTAssertNotEqualObjects(dateMarkRange1, timeMarkRange3);
    XCTAssertNotEqualObjects(dateMarkRange1, timeMarkRange4);
    XCTAssertNotEqualObjects(dateMarkRange1, timeMarkRange5);
}

- (void)testHash
{
    SRGMarkRange *timeMarkRange1 = [SRGMarkRange rangeFromTimeInSeconds:5. toTimeInSeconds:10.];
    SRGMarkRange *timeMarkRange2 = [SRGMarkRange rangeFromTimeInSeconds:5. toTimeInSeconds:10.];
    SRGMarkRange *timeMarkRange3 = [SRGMarkRange rangeFromTimeInSeconds:7. toTimeInSeconds:10.];
    SRGMarkRange *timeMarkRange4 = [SRGMarkRange rangeFromTimeInSeconds:5. toTimeInSeconds:12.];
    SRGMarkRange *timeMarkRange5 = [SRGMarkRange rangeFromTimeInSeconds:7. toTimeInSeconds:12.];
    
    NSDate *date = NSDate.date;
    SRGMarkRange *dateMarkRange1 = [SRGMarkRange rangeFromDate:date toDate:[date dateByAddingTimeInterval:10.]];
    SRGMarkRange *dateMarkRange2 = [SRGMarkRange rangeFromDate:date toDate:[date dateByAddingTimeInterval:10.]];
    SRGMarkRange *dateMarkRange3 = [SRGMarkRange rangeFromDate:[date dateByAddingTimeInterval:2.] toDate:[date dateByAddingTimeInterval:10.]];
    SRGMarkRange *dateMarkRange4 = [SRGMarkRange rangeFromDate:date toDate:[NSDate dateWithTimeIntervalSinceNow:12.]];
    SRGMarkRange *dateMarkRange5 = [SRGMarkRange rangeFromDate:[date dateByAddingTimeInterval:2.] toDate:[date dateByAddingTimeInterval:10.]];
    
    XCTAssertEqual(timeMarkRange1.hash, timeMarkRange1.hash);
    XCTAssertEqual(timeMarkRange1.hash, timeMarkRange2.hash);
    XCTAssertNotEqual(timeMarkRange1.hash, timeMarkRange3.hash);
    XCTAssertNotEqual(timeMarkRange1.hash, timeMarkRange4.hash);
    XCTAssertNotEqual(timeMarkRange1.hash, timeMarkRange5.hash);
    XCTAssertNotEqual(timeMarkRange1.hash, dateMarkRange1.hash);
    XCTAssertNotEqual(timeMarkRange1.hash, dateMarkRange2.hash);
    XCTAssertNotEqual(timeMarkRange1.hash, dateMarkRange3.hash);
    XCTAssertNotEqual(timeMarkRange1.hash, dateMarkRange4.hash);
    XCTAssertNotEqual(timeMarkRange1.hash, dateMarkRange5.hash);
    
    XCTAssertEqual(dateMarkRange1.hash, dateMarkRange1.hash);
    XCTAssertEqual(dateMarkRange1.hash, dateMarkRange2.hash);
    XCTAssertNotEqual(dateMarkRange1.hash, dateMarkRange3.hash);
    XCTAssertNotEqual(dateMarkRange1.hash, dateMarkRange4.hash);
    XCTAssertNotEqual(dateMarkRange1.hash, dateMarkRange5.hash);
    XCTAssertNotEqual(dateMarkRange1.hash, timeMarkRange1.hash);
    XCTAssertNotEqual(dateMarkRange1.hash, timeMarkRange2.hash);
    XCTAssertNotEqual(dateMarkRange1.hash, timeMarkRange3.hash);
    XCTAssertNotEqual(dateMarkRange1.hash, timeMarkRange4.hash);
    XCTAssertNotEqual(dateMarkRange1.hash, timeMarkRange5.hash);
}

- (void)testTimeConversionsWithoutController
{
    SRGMarkRange *markRange1 = [SRGMarkRange rangeFromTimeInSeconds:5. toTimeInSeconds:10.];
    TestAssertEqualTimeInSeconds([markRange1.fromMark timeForMediaPlayerController:nil], 5.);
    TestAssertEqualTimeInSeconds([markRange1.toMark timeForMediaPlayerController:nil], 10.);
    
    NSDate *date = NSDate.date;
    SRGMarkRange *markRange2 = [SRGMarkRange rangeFromDate:date toDate:[date dateByAddingTimeInterval:10.]];
    TestAssertEqualTimeInSeconds([markRange2.fromMark timeForMediaPlayerController:nil], 0.);
    TestAssertEqualTimeInSeconds([markRange2.toMark timeForMediaPlayerController:nil], 0.);
}

@end

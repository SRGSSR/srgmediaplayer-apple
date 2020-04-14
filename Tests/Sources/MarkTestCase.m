//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaPlayerBaseTestCase.h"
#import "TestMacros.h"

#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface MarkTestCase : MediaPlayerBaseTestCase

@end

@implementation MarkTestCase

#pragma mark Tests

- (void)testMarkAtTime
{
    SRGMark *mark = [SRGMark markAtTime:CMTimeMakeWithSeconds(7., NSEC_PER_SEC)];
    TestAssertEqualTimeInSeconds(mark.time, 7.);
    XCTAssertNil(mark.date);
}

- (void)testMarkAtTimeInSeconds
{
    SRGMark *mark = [SRGMark markAtTimeInSeconds:9.];
    TestAssertEqualTimeInSeconds(mark.time, 9.);
    XCTAssertNil(mark.date);
}

- (void)testMarkAtDate
{
    NSDate *date = NSDate.date;
    SRGMark *mark = [SRGMark markAtDate:date];
    TestAssertEqualTimeInSeconds(mark.time, 0.);
    XCTAssertEqualObjects(mark.date, date);
}

- (void)testEquality
{
    SRGMark *timeMark1 = [SRGMark markAtTime:CMTimeMakeWithSeconds(7., NSEC_PER_SEC)];
    SRGMark *timeMark2 = [SRGMark markAtTime:CMTimeMakeWithSeconds(7., NSEC_PER_SEC)];
    SRGMark *timeMark3 = [SRGMark markAtTime:CMTimeMakeWithSeconds(9., NSEC_PER_SEC)];
    
    NSDate *date = NSDate.date;
    SRGMark *dateMark1 = [SRGMark markAtDate:date];
    SRGMark *dateMark2 = [SRGMark markAtDate:date];
    SRGMark *dateMark3 = [SRGMark markAtDate:[NSDate dateWithTimeIntervalSinceNow:10.]];
    
    XCTAssertEqualObjects(timeMark1, timeMark1);
    XCTAssertEqualObjects(timeMark1, timeMark2);
    XCTAssertNotEqualObjects(timeMark1, timeMark3);
    XCTAssertNotEqualObjects(timeMark1, dateMark1);
    XCTAssertNotEqualObjects(timeMark1, dateMark2);
    XCTAssertNotEqualObjects(timeMark1, dateMark3);
    
    XCTAssertEqualObjects(dateMark1, dateMark1);
    XCTAssertEqualObjects(dateMark1, dateMark2);
    XCTAssertNotEqualObjects(dateMark1, dateMark3);
    XCTAssertNotEqualObjects(dateMark1, timeMark1);
    XCTAssertNotEqualObjects(dateMark1, timeMark2);
    XCTAssertNotEqualObjects(dateMark1, timeMark3);
}

- (void)testHash
{
    SRGMark *timeMark1 = [SRGMark markAtTime:CMTimeMakeWithSeconds(7., NSEC_PER_SEC)];
    SRGMark *timeMark2 = [SRGMark markAtTime:CMTimeMakeWithSeconds(7., NSEC_PER_SEC)];
    SRGMark *timeMark3 = [SRGMark markAtTime:CMTimeMakeWithSeconds(9., NSEC_PER_SEC)];
    
    NSDate *date = NSDate.date;
    SRGMark *dateMark1 = [SRGMark markAtDate:date];
    SRGMark *dateMark2 = [SRGMark markAtDate:date];
    SRGMark *dateMark3 = [SRGMark markAtDate:[NSDate dateWithTimeIntervalSinceNow:10.]];
    
    XCTAssertEqual(timeMark1.hash, timeMark1.hash);
    XCTAssertEqual(timeMark1.hash, timeMark2.hash);
    XCTAssertNotEqual(timeMark1.hash, timeMark3.hash);
    XCTAssertNotEqual(timeMark1.hash, dateMark1.hash);
    XCTAssertNotEqual(timeMark1.hash, dateMark2.hash);
    XCTAssertNotEqual(timeMark1.hash, dateMark3.hash);
    
    XCTAssertEqual(dateMark1.hash, dateMark1.hash);
    XCTAssertEqual(dateMark1.hash, dateMark2.hash);
    XCTAssertNotEqual(dateMark1.hash, dateMark3.hash);
    XCTAssertNotEqual(dateMark1.hash, timeMark1.hash);
    XCTAssertNotEqual(dateMark1.hash, timeMark2.hash);
    XCTAssertNotEqual(dateMark1.hash, timeMark3.hash);
}

@end

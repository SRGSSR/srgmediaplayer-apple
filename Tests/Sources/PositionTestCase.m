//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaPlayerBaseTestCase.h"
#import "TestMacros.h"

#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface PositionTestCase : MediaPlayerBaseTestCase

@end

@implementation PositionTestCase

#pragma mark Tests

- (void)testCreation
{
    SRGPosition *position1 = [[SRGPosition alloc] initWithTime:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) toleranceBefore:CMTimeMakeWithSeconds(2., NSEC_PER_SEC) toleranceAfter:CMTimeMakeWithSeconds(7., NSEC_PER_SEC)];
    TestAssertEqualTimeInSeconds(position1.time, 1.);
    TestAssertEqualTimeInSeconds(position1.toleranceBefore, 2.);
    TestAssertEqualTimeInSeconds(position1.toleranceAfter, 7.);
    
    SRGPosition *position2 = [[SRGPosition alloc] init];
    TestAssertEqualTimeInSeconds(position2.time, 0.);
    TestAssertEqualTimeInSeconds(position2.toleranceBefore, 0.);
    TestAssertEqualTimeInSeconds(position2.toleranceAfter, 0.);
}

- (void)testDefaultPosition
{
    SRGPosition *position = [SRGPosition defaultPosition];
    TestAssertEqualTimeInSeconds(position.time, 0.);
    TestAssertEqualTimeInSeconds(position.toleranceBefore, 0.);
    TestAssertEqualTimeInSeconds(position.toleranceAfter, 0.);
}

- (void)testPositionAtTime
{
    SRGPosition *position = [SRGPosition positionAtTime:CMTimeMakeWithSeconds(7., NSEC_PER_SEC)];
    TestAssertEqualTimeInSeconds(position.time, 7.);
    TestAssertEqualTimeInSeconds(position.toleranceBefore, 0.);
    TestAssertEqualTimeInSeconds(position.toleranceAfter, 0.);
}

- (void)testPositionAtTimeInSeconds
{
    SRGPosition *position = [SRGPosition positionAtTimeInSeconds:9.];
    TestAssertEqualTimeInSeconds(position.time, 9.);
    TestAssertEqualTimeInSeconds(position.toleranceBefore, 0.);
    TestAssertEqualTimeInSeconds(position.toleranceAfter, 0.);
}

- (void)testPositionAroundTime
{
    SRGPosition *position = [SRGPosition positionAroundTime:CMTimeMakeWithSeconds(11., NSEC_PER_SEC)];
    TestAssertEqualTimeInSeconds(position.time, 11.);
    XCTAssertTrue(CMTIME_COMPARE_INLINE(position.toleranceBefore, ==, kCMTimePositiveInfinity));
    XCTAssertTrue(CMTIME_COMPARE_INLINE(position.toleranceAfter, ==, kCMTimePositiveInfinity));
}

- (void)testPositionAroundTimeInSeconds
{
    SRGPosition *position = [SRGPosition positionAroundTimeInSeconds:5.];
    TestAssertEqualTimeInSeconds(position.time, 5.);
    XCTAssertTrue(CMTIME_COMPARE_INLINE(position.toleranceBefore, ==, kCMTimePositiveInfinity));
    XCTAssertTrue(CMTIME_COMPARE_INLINE(position.toleranceAfter, ==, kCMTimePositiveInfinity));
}

- (void)testCustomPosition
{
    SRGPosition *position = [SRGPosition positionWithTime:CMTimeMakeWithSeconds(17., NSEC_PER_SEC) toleranceBefore:CMTimeMakeWithSeconds(19., NSEC_PER_SEC) toleranceAfter:CMTimeMakeWithSeconds(18., NSEC_PER_SEC)];
    TestAssertEqualTimeInSeconds(position.time, 17.);
    TestAssertEqualTimeInSeconds(position.toleranceBefore, 19.);
    TestAssertEqualTimeInSeconds(position.toleranceAfter, 18.);
}

- (void)testPositionWithInvalidTimes
{
    SRGPosition *position1 = [SRGPosition positionWithTime:kCMTimeInvalid toleranceBefore:CMTimeMakeWithSeconds(19., NSEC_PER_SEC) toleranceAfter:CMTimeMakeWithSeconds(18., NSEC_PER_SEC)];
    TestAssertEqualTimeInSeconds(position1.time, 0.);
    TestAssertEqualTimeInSeconds(position1.toleranceBefore, 19.);
    TestAssertEqualTimeInSeconds(position1.toleranceAfter, 18.);
    
    SRGPosition *position2 = [SRGPosition positionWithTime:CMTimeMakeWithSeconds(17., NSEC_PER_SEC) toleranceBefore:kCMTimeInvalid toleranceAfter:CMTimeMakeWithSeconds(18., NSEC_PER_SEC)];
    TestAssertEqualTimeInSeconds(position2.time, 17.);
    TestAssertEqualTimeInSeconds(position2.toleranceBefore, 0.);
    TestAssertEqualTimeInSeconds(position2.toleranceAfter, 18.);
    
    SRGPosition *position3 = [SRGPosition positionWithTime:CMTimeMakeWithSeconds(17., NSEC_PER_SEC) toleranceBefore:CMTimeMakeWithSeconds(19., NSEC_PER_SEC) toleranceAfter:kCMTimeInvalid];
    TestAssertEqualTimeInSeconds(position3.time, 17.);
    TestAssertEqualTimeInSeconds(position3.toleranceBefore, 19.);
    TestAssertEqualTimeInSeconds(position3.toleranceAfter, 0.);
}

@end

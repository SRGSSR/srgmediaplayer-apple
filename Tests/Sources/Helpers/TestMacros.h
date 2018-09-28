//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

#define TestAssertIndefiniteTime(time)                                  XCTAssertTrue(CMTIME_IS_INDEFINITE(time))

#define TestAssertEqualTimeInSeconds(time, seconds)                     XCTAssertEqual(round(CMTimeGetSeconds(time)), round(seconds))
#define TestAssertNotEqualTimeInSeconds(time, seconds)                  XCTAssertNotEqual(round(CMTimeGetSeconds(time)), round(seconds))

#define TestAssertAlmostEqual(time, seconds, toleranceInSeconds)        XCTAssertTrue(CMTIME_COMPARE_INLINE(CMTimeAbsoluteValue(CMTimeSubtract(time, CMTimeMakeWithSeconds(seconds, NSEC_PER_SEC))), <, CMTimeMakeWithSeconds(toleranceInSeconds, NSEC_PER_SEC)))
#define TestAssertAlmostButNotEqual(time, seconds, toleranceInSeconds)  XCTAssertNotEqual(round(CMTimeGetSeconds(time)), round(seconds)); TestAssertAlmostEqual(time, seconds, toleranceInSeconds)

//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

#define TestAssertIndefiniteTime(time)              XCTAssertTrue(CMTIME_IS_INDEFINITE(time))
#define TestAssertEqualTimeInSeconds(time, seconds) XCTAssertEqual((NSInteger)CMTimeGetSeconds(time), (NSInteger)(seconds))

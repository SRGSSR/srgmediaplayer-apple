//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaPlayerBaseTestCase.h"
#import "TestMacros.h"

@import SRGMediaPlayer;

@interface ConstantsTestCase : MediaPlayerBaseTestCase

@end

@implementation ConstantsTestCase

#pragma mark Tests

- (void)testEffectiveEndTolerance
{
    TestAssertEqualTimeInSeconds(SRGMediaPlayerEffectiveEndTolerance(0., 0.f, 60.), 0.);
    TestAssertEqualTimeInSeconds(SRGMediaPlayerEffectiveEndTolerance(10., 0.f, 60.), 10.);
    TestAssertEqualTimeInSeconds(SRGMediaPlayerEffectiveEndTolerance(0., 0.1f, 60.), 6.);
    TestAssertEqualTimeInSeconds(SRGMediaPlayerEffectiveEndTolerance(10., 0.1f, 60.), 6.);
    TestAssertEqualTimeInSeconds(SRGMediaPlayerEffectiveEndTolerance(10., 0.1f, 120.), 10.);
}

@end

//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMark.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Describes a range enclosed by two marks.
 */
@interface SRGMarkRange : NSObject

/**
 *  Range between the two specified marks.
 */
+ (SRGMarkRange *)rangeFromMark:(SRGMark *)fromMark toMark:(SRGMark *)toMark;

/**
 *  Range end marks.
 */
@property (nonatomic, readonly) SRGMark *fromMark;
@property (nonatomic, readonly) SRGMark *toMark;

@end

NS_ASSUME_NONNULL_END

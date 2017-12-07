//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

#import "Segment.h"

NS_ASSUME_NONNULL_BEGIN

@interface Media : NSObject

+ (nullable NSArray<Media *> *)mediasFromFileAtPath:(NSString *)filePath;

@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly) NSURL *URL;
@property (nonatomic, readonly) BOOL is360;

@property (nonatomic, readonly, nullable) NSArray<Segment *> *segments;

@end

NS_ASSUME_NONNULL_END

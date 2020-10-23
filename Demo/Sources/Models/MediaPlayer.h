//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface MediaPlayer : NSObject

+ (MediaPlayer *)mediaPlayerWithName:(NSString *)name class:(Class)playerClass;

@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly) Class playerClass;

@end

NS_ASSUME_NONNULL_END

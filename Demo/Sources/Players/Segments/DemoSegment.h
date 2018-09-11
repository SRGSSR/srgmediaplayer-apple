//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DemoSegment : NSObject <SRGSegment>

- (instancetype)initWithDictionary:(NSDictionary *)dictionary NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, copy) NSString *name;

@end

NS_ASSUME_NONNULL_END

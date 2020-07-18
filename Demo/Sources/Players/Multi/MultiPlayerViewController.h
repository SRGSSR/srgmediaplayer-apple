//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Media.h"

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface MultiPlayerViewController : UIViewController

- (instancetype)initWithMedias:(NSArray<Media *> *)medias;

@end

NS_ASSUME_NONNULL_END

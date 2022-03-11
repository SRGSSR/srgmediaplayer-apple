//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface SRGSettingsSegmentCell : UITableViewCell

- (void)setItems:(NSArray<NSString *> *)items reader:(NSInteger (^)(void))reader writer:(void (^)(NSInteger index))writer;

@end

NS_ASSUME_NONNULL_END

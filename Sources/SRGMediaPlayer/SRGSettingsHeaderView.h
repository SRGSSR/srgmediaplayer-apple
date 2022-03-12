//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface SRGSettingsHeaderView : UITableViewHeaderFooterView

@property (class, nonatomic, readonly) CGFloat height;

@property (nonatomic, copy) NSString *title;
@property (nonatomic) UIImage *image;

@end

NS_ASSUME_NONNULL_END

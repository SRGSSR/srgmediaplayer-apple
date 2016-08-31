//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MediasViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource>

- (instancetype)initWithMediaFileName:(NSString *)mediaFileName;

@end

@interface MediasViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TVMediaPlayerType) {
    TVMediaPlayerTypeSystem,
    TVMediaPlayerTypeStandard
};

@interface TVMediasViewController : UITableViewController

- (instancetype)initWithConfigurationFileName:(NSString *)configurationFileName mediaPlayerType:(TVMediaPlayerType)mediaPlayerType;

@end

@interface TVMediasViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

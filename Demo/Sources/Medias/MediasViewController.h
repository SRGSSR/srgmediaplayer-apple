//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MediaPlayerType) {
    MediaPlayerTypeStandard,
    MediaPlayerTypeSegments,
    MediaPlayerTypeMulti API_UNAVAILABLE(tvos)
};

@interface MediasViewController : UITableViewController

- (instancetype)initWithTitle:(NSString *)title configurationFileName:(NSString *)configurationFileName mediaPlayerType:(MediaPlayerType)mediaPlayerType;

@end


@interface MediasViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

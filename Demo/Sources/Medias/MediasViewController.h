//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MediaPlayerType) {
    MediaPlayerTypeStandard,
    MediaPlayerTypeSegments,
    MediaPlayerTypeTimeshift,
    MediaPlayerTypeMulti
};

@interface MediasViewController : UITableViewController

- (instancetype)initWithConfigurationFileName:(NSString *)configurationFileName mediaPlayerType:(MediaPlayerType)mediaPlayerType;

@end

@interface MediasViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

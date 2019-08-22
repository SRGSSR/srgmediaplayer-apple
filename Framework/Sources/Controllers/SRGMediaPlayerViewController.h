//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController.h"

#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SRGMediaPlayerViewController;

/**
 *  Player view controller delegate protocol.
 */
@protocol SRGMediaPlayerViewControllerDelegate <AVPlayerViewControllerDelegate>

@optional

#if TARGET_OS_TV

/**
 *  Return the navigation markers to be displayed for the specified segments.
 */
- (NSArray<AVTimedMetadataGroup *> *)playerViewController:(SRGMediaPlayerViewController *)playerViewController navigationMarkersForSegments:(NSArray<id<SRGSegment>> *)segments;

#endif

@end

/**
 *  A lightweight `AVPlayerViewController` subclass using an `SRGMediaPlayerController` for playback. This class provides
 *  standard Apple player user experience, at the expense of a few limitations:
 *    - 360° medias are not playable with monoscopic or stereoscopic support.
 *    - Background playback behavior cannot be customized.
 *
 *  If you need one of the above features you should implement your own player layout instead.
 *
 *  Since `AVPlayerViewController` manages its video player layer as well, note that the picture in picture controller
 *  associated with an `SRGMediaPlayerController` is not used.
 */
@interface SRGMediaPlayerViewController : AVPlayerViewController

/**
 *  Instantiate a view controller whose playback is managed by the specified controller. If none is provided a default
 *  one will be automatically created.
 */
- (instancetype)initWithController:(nullable SRGMediaPlayerController *)controller;

/**
 *  The controller used for playback.
 */
@property (nonatomic, readonly) SRGMediaPlayerController *controller;

/**
 *  The player view controller delegate.
 */
@property (nonatomic, weak) id<SRGMediaPlayerViewControllerDelegate> delegate;

@end

@interface SRGMediaPlayerViewController (Unavailable)

@property (nonatomic, nullable) AVPlayer *player NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

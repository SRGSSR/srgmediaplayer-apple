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
@protocol SRGMediaPlayerViewControllerDelegate <NSObject>

@optional

#if TARGET_OS_TV

/**
 *  The player view controller can display segments if navigation markers are provided.
 */
- (NSArray<AVTimedMetadataGroup *> *)mediaPlayerViewController:(SRGMediaPlayerViewController *)mediaPlayerViewController navigationMarkersForDisplayableSegments:(NSArray<id<SRGSegment>> *)segments;

#endif

@end

/**
 *  A lightweight `AVPlayerViewController` subclass, but using an `SRGMediaPlayerController` for playback. This class
 *  provides standard Apple user experience at the expense of a few limitations:
 *    - 360° medias are not playable with monoscopic or stereoscopic support.
 *    - Background playback behavior cannot be customized.
 *
 *  If you need one of these features, implement your own player layout instead.
 *
 *  Since `AVPlayerViewController` also manages video player layers as well, note that the picture in picture controller
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
 *  The srg player view controller delegate.
 */
@property (nonatomic, weak) id<SRGMediaPlayerViewControllerDelegate> srg_delegate;

@end

@interface SRGMediaPlayerViewController (Unavailable)

@property (nonatomic, strong, nullable) AVPlayer *player NS_UNAVAILABLE;

@property (nonatomic, copy) NSArray<AVInterstitialTimeRange *> *interstitialTimeRanges NS_UNAVAILABLE;

@property (nonatomic, copy) NSArray<AVNavigationMarkersGroup *> *navigationMarkerGroups NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

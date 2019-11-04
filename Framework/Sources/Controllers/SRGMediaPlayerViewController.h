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
 *  Return optional external metadata to display in the Info panel.
 *
 *  @discussion For a metadata item to be presented in the Info panel, you need to provide values for the item’s identifier, value
 *              and extendedLanguageTag.
 */
- (nullable NSArray<AVMetadataItem *> *)playerViewControllerExternalMetadata:(SRGMediaPlayerViewController *)playerViewController;

/**
 *  Return the navigation markers to be displayed for the specified segments.
 */
- (nullable NSArray<AVTimedMetadataGroup *> *)playerViewController:(SRGMediaPlayerViewController *)playerViewController navigationMarkersForSegments:(NSArray<id<SRGSegment>> *)segments;

#endif

@end

/**
 *  A lightweight `AVPlayerViewController` subclass using an `SRGMediaPlayerController` for playback. This class provides
 *  standard Apple player user experience, at the expense of a few limitations:
 *    - 360° medias are not playable with monoscopic or stereoscopic support.
 *    - Background playback behavior cannot be customized.
 *
 *  If you need one of the above features you should implement your own player layout instead.
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

/**
 *  Reload data (e.g. external metadata and navigation markers on tvOS) displayed by the player.
 */
- (void)reloadData;

@end

@interface SRGMediaPlayerViewController (Unavailable)

@property (nonatomic, nullable) AVPlayer *player NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

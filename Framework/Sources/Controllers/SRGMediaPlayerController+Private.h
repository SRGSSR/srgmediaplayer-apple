//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaPlayerController.h"

NS_ASSUME_NONNULL_BEGIN

@interface SRGMediaPlayerController (Private)

/**
 *  Bind the controller to an `AVPlayerViewController` instance. The user experience will be slightly limited:
 *    - 360° medias are not playable with monoscopic or stereoscopic support.
 *    - Background playback behavior cannot be customized.
 *
 *  Moreover, since `AVPlayerViewController` manages its video player layer as well, note that the picture in picture
 *  controller associated with `SRGMediaPlayerController` is not used.
 *
 *  If the controller is bound to an `AVPlayerViewController`, it will be unbound first.
 */
- (void)bindToPlayerViewController:(AVPlayerViewController *)playerViewController;

/**
 *  Unbind the controller from its current `AVPlayerViewController`, if any. If no such binding currently exists, this
 *  method does nothing.
 */
- (void)unbindFromCurrentPlayerViewController;

/**
 *  Select an option in the group having the specified characteristic.
 */
- (void)selectMediaOption:(nullable AVMediaSelectionOption *)option inMediaSelectionGroupWithCharacteristic:(AVMediaCharacteristic)characteristic;

/**
 *  Perform automatic option selection in the group having the specified characteristic.
 */
- (void)selectMediaOptionAutomaticallyInMediaSelectionGroupWithCharacteristic:(AVMediaCharacteristic)characteristic;

/**
 *  Return the selected option in the group having the specified characteristic, if any.
 */
- (nullable AVMediaSelectionOption *)selectedMediaOptionInMediaSelectionGroupWithCharacteristic:(AVMediaCharacteristic)characteristic;

/**
 *  Return `YES` iff the current subtitle selection matches the one expected for automatic mode.
 *
 *  @discussion This method can return `YES` even if automatic mode is not active.
 */
@property (nonatomic, readonly) BOOL matchesAutomaticSubtitleSelection;

/**
 *  Return the time corresponding to a mark, in the stream reference frame.
 */
- (CMTime)streamTimeForMark:(SRGMark *)mark;

/**
 *  Return the time range corresponding to a mark range, in the stream reference frame.
 */
- (CMTimeRange)streamTimeRangeForMarkRange:(SRGMarkRange *)markRange;

/**
 *  Return the date corresponding to some time, in the stream reference frame.
 *
 *  @discussion Returns `nil` if the stream cannot be associated with a date, e.g. in the case of on-demand streams.
 */
- (nullable NSDate *)streamDateForTime:(CMTime)time;

@end

NS_ASSUME_NONNULL_END

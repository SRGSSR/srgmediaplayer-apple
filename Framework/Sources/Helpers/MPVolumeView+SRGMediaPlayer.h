//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <MediaPlayer/MediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPVolumeView (SRGMediaPlayer)

/**
 *  Return the Airplay button within the volume view
 */
@property (nonatomic, readonly) UIButton *srg_airplayButton;

@end

NS_ASSUME_NONNULL_END

//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

#import "SRGMediaPlayerController.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  An activity indicator displaying the current status of the associated media player controller.
 *
 *  Simply install an instance somewhere onto your custom player interface and bind it to a media player controller.
 *
 *  Besides setting the mediaPlayerController outlet and appearance properties (color, size, alpha), you should never:
 *    - Call `startAnimating` or `stopAnimating`.
 *    - Change the values of the `hidden` or `hidesWhenStopped` properties.
 *  These properties are automatically managed for you, altering them results in undefined behavior.
 */
@interface SRGPlaybackActivityIndicatorView : UIActivityIndicatorView

/**
 *  The media player which the playback button must be associated with.
 */
@property (nonatomic, weak, nullable) IBOutlet SRGMediaPlayerController *mediaPlayerController;

@end

NS_ASSUME_NONNULL_END

//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

@class RTSMediaPlayerController;

/**
 * Protocol describing how a media player controller receives the data it requires
 */
@protocol RTSMediaPlayerControllerDataSource <NSObject>

/**
 *  Method called to retrieve the URL to be played for a given media identifier
 *
 *  @param mediaPlayerController The media player controller making the request
 *  @param identifier            The identifier for which the URL must be retrieved
 *  @param completionHandler     The block which the implementation must call to return the URL to the controller, or
 *                               an error if it could not be retrieved
 */
- (void)mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
	  contentURLForIdentifier:(NSString *)identifier
			completionHandler:(void (^)(NSURL *contentURL, NSError *error))completionHandler;

@end

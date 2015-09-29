//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

/**
 *  Domain for media player errors
 */
FOUNDATION_EXTERN NSString * const RTSMediaPlayerErrorDomain;

/**
 *  Media player error codes
 */
typedef NS_ENUM(NSInteger, RTSMediaPlayerError){
	/**
	 *  An unknown error has occurred
	 */
	RTSMediaPlayerErrorUnknown,
};

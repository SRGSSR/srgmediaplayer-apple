//
//  CSStreamingTag.h
//  comScore
//
//  Copyright (c) 2014 comScore. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSStreamingTag : NSObject

- (void) playAdvertisement __deprecated_msg("Calling deprecated function 'playAdvertisement'. Please call 'playVideoAdvertisement' or 'playAudioAdvertisement' functions instead.");
- (void) playVideoAdvertisementWithMetadata:(NSDictionary *)metadata;
- (void) playVideoAdvertisement;
- (void) playAudioAdvertisementWithMetadata:(NSDictionary *)metadata;
- (void) playAudioAdvertisement;
- (void) playContentPartWithMetadata:(NSDictionary *)metadata __deprecated_msg("Calling deprecated function 'playContentPart'. Please call 'playVideoContentPart' or 'playAudioContentPart' functions instead.");
- (void) playVideoContentPartWithMetadata:(NSDictionary *)metadata;
- (void) playAudioContentPartWithMetadata:(NSDictionary *)metadata;
- (void) stop;

@end

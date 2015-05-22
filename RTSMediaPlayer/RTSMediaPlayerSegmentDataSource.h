//
//  Created by Samuel Défago on 21.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RTSMediaPlayerSegmentView;

@protocol RTSMediaPlayerSegmentDataSource <NSObject>

@required
- (void) mediaPlayerSegmentView:(id<RTSMediaPlayerSegmentView>)mediaPlayerSegmentView segmentsForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSArray *segments, NSError *error))completionHandler;

@end

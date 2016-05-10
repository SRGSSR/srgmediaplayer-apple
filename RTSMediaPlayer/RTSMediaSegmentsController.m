//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <AVFoundation/AVFoundation.h>
#import <libextobjc/EXTScope.h>

#import "RTSMediaPlayerController.h"
#import "RTSMediaPlayerController+Private.h"
#import "RTSMediaSegment.h"
#import "RTSMediaSegmentsController.h"
#import "RTSMediaPlayerLogger.h"
#import "RTSMediaSegmentsDataSource.h"

NSTimeInterval const RTSMediaPlaybackTickInterval = 0.1;
NSString * const RTSMediaPlaybackSegmentDidChangeNotification = @"RTSMediaPlaybackSegmentDidChangeNotification";
NSString * const RTSMediaPlaybackSegmentChangeSegmentInfoKey = @"RTSMediaPlaybackSegmentChangeSegmentInfoKey";
NSString * const RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey = @"RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey";
NSString * const RTSMediaPlaybackSegmentChangeValueInfoKey = @"RTSMediaPlaybackSegmentChangeValueInfoKey";
NSString * const RTSMediaPlaybackSegmentChangeUserSelectInfoKey = @"RTSMediaPlaybackSegmentChangeUserSelectInfoKey";

@interface RTSMediaSegmentsController ()
@property(nonatomic, strong) NSArray *segments;
@property(nonatomic, strong) id playerTimeObserver;
@property(nonatomic, weak) id<RTSMediaSegment> lastPlaybackPositionLogicalSegment;
@property(nonatomic, strong) id segmentsRequestHandle;
@end

@implementation RTSMediaSegmentsController

- (void)setPlayerController:(RTSMediaPlayerController *)playerController
{
    _playerController = playerController;
    
    playerController.segmentsController = self;
}

- (void)reloadSegmentsForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSError *error))completionHandler
{
    NSParameterAssert(identifier);
    
    if (!self.playerController) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"Trying to reload data requires to have a player controller."
                                     userInfo:nil];
    }
    
    if (!self.dataSource) {
        self.segments = [NSArray new];
    }
    
    [self removeBlockingTimeObserver];
	
    self.lastPlaybackPositionLogicalSegment = nil;
    
    RTSMediaSegmentsCompletionHandler reloadCompletionBlock = ^(NSString *identifier, NSArray *segments, NSError *error) {
		self.segmentsRequestHandle = nil;
		
        if (error) {
            if (completionHandler) {
                completionHandler(error);
            }
            return;
        }
        
		self.segments = segments;
		
        [self addBlockingTimeObserver];
        
        if (completionHandler) {
            completionHandler(nil);
        }
    };
	
	if (self.segmentsRequestHandle) {
		[self.dataSource cancelSegmentsRequest:self.segmentsRequestHandle];
	}
    
    self.segmentsRequestHandle = [self.dataSource segmentsController:self segmentsForIdentifier:identifier withCompletionHandler:reloadCompletionBlock];
}

- (void)removeBlockingTimeObserver
{
    if (self.playerController && self.playerTimeObserver) {
        [self.playerController removePeriodicTimeObserver:self.playerTimeObserver];
        self.playerTimeObserver = nil;
    }
}

- (void)addBlockingTimeObserver
{
    @weakify(self);
    
    // This block will necessarily run on the main thread. See addPeriodicTimeObserverForInterval:... method.
    void (^checkBlock)(CMTime) = ^(CMTime time) {
        @strongify(self);
        
        if (self.playerController.playbackState != RTSMediaPlaybackStatePlaying) {
            return;
        }
		
		// We assume that all logical segments of a full length have an identifier that is IDENTICAL to the fullLength's.
        __block id<RTSMediaSegment> currentSegment = nil;
        [self.segments enumerateObjectsUsingBlock:^(id<RTSMediaSegment> segment, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([segment.segmentIdentifier isEqualToString:self.playerController.identifier] && segment.logical) {
				if (CMTimeRangeContainsTime(segment.timeRange, time)) {
					currentSegment = segment;
					*stop = YES;
				}
            }
        }];
        
        if (self.lastPlaybackPositionLogicalSegment != currentSegment) {
			NSDictionary *userInfo = nil;
			
            if (!currentSegment || (self.lastPlaybackPositionLogicalSegment && currentSegment.blocked)) {
				userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentEnd),
							 RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey: self.lastPlaybackPositionLogicalSegment,
							 RTSMediaPlaybackSegmentChangeUserSelectInfoKey: @(NO)};
			}
			else if (currentSegment && !self.lastPlaybackPositionLogicalSegment && !currentSegment.blocked) {
				userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentStart),
							 RTSMediaPlaybackSegmentChangeSegmentInfoKey: currentSegment,
							 RTSMediaPlaybackSegmentChangeUserSelectInfoKey: @(NO)};
			}
			else if (currentSegment && self.lastPlaybackPositionLogicalSegment) {
				userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentSwitch),
							 RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey: self.lastPlaybackPositionLogicalSegment,
							 RTSMediaPlaybackSegmentChangeSegmentInfoKey: currentSegment,
							 RTSMediaPlaybackSegmentChangeUserSelectInfoKey: @(NO)};
			}
			
			if (userInfo) {
				[[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlaybackSegmentDidChangeNotification
																	object:self
																  userInfo:userInfo];
			}
            
			self.lastPlaybackPositionLogicalSegment = currentSegment;			
		}
		
        // Managing blocked segments
		if (currentSegment.blocked) {
            NSDictionary *userInfo = userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentSeekUponBlockingStart),
                                                  RTSMediaPlaybackSegmentChangeSegmentInfoKey: currentSegment};
            
            [[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlaybackSegmentDidChangeNotification
                                                                object:self
                                                              userInfo:userInfo];
            
            [self.playerController seekToTime:CMTimeRangeGetEnd(currentSegment.timeRange) completionHandler:^(BOOL finished) {
                NSDictionary *userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentSeekUponBlockingEnd),
                                           RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey: currentSegment};
                [[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlaybackSegmentDidChangeNotification
                                                                    object:self
                                                                  userInfo:userInfo];
                
                self.lastPlaybackPositionLogicalSegment = nil;
                
                [self.playerController pause];
            }];
		}
	};
	
    CMTime interval = CMTimeMakeWithSeconds(RTSMediaPlaybackTickInterval, NSEC_PER_SEC);
    self.playerTimeObserver = [self.playerController addPeriodicTimeObserverForInterval:interval
                                                                                  queue:nil
                                                                             usingBlock:checkBlock];
}

- (NSArray *)visibleSegments
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id<RTSMediaSegment>segment, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [segment isVisible];
    }];
    return [self.segments filteredArrayUsingPredicate:predicate];
}

- (id<RTSMediaSegment>)currentSegment
{
    return self.lastPlaybackPositionLogicalSegment;
}

- (void)playSegment:(id<RTSMediaSegment>)segment
{
    if (segment.logical) {
        NSDictionary *userInfo = nil;
        if (!self.lastPlaybackPositionLogicalSegment) {
            userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentStart),
                         RTSMediaPlaybackSegmentChangeSegmentInfoKey: segment,
                         RTSMediaPlaybackSegmentChangeUserSelectInfoKey: @(YES)};
        }
        else {
            userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentSwitch),
                         RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey: self.lastPlaybackPositionLogicalSegment,
                         RTSMediaPlaybackSegmentChangeSegmentInfoKey: segment,
                         RTSMediaPlaybackSegmentChangeUserSelectInfoKey: @(YES)};
        }
        
        // Immediately send the event. We thus also update the current segment information right here
        self.lastPlaybackPositionLogicalSegment = segment;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlaybackSegmentDidChangeNotification
                                                            object:self
                                                          userInfo:userInfo];
    }
    else {
        self.lastPlaybackPositionLogicalSegment = nil;
    }
    
    if ([self.playerController.identifier isEqualToString:segment.segmentIdentifier]) {
        [self.playerController seekToTime:segment.timeRange.start completionHandler:^(BOOL finished) {
            if (finished) {
                [self.playerController play];
            }
        }];
    }
    else {
        [self.playerController playIdentifier:segment.segmentIdentifier];
    }
}

@end

@implementation RTSMediaPlayerController (RTSMediaSegmentsController)

@dynamic segmentsController;

@end

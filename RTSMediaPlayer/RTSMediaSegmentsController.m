//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <AVFoundation/AVFoundation.h>
#import <libextobjc/EXTScope.h>

#import "RTSMediaPlayerController.h"
#import "RTSMediaSegment.h"
#import "RTSMediaSegmentsController.h"
#import "RTSMediaPlayerLogger.h"

NSTimeInterval const RTSMediaPlaybackTickInterval = 0.1;
NSString * const RTSMediaPlaybackSegmentDidChangeNotification = @"RTSMediaPlaybackSegmentDidChangeNotification";
NSString * const RTSMediaPlaybackSegmentChangeSegmentInfoKey = @"RTSMediaPlaybackSegmentChangeSegmentInfoKey";
NSString * const RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey = @"RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey";
NSString * const RTSMediaPlaybackSegmentChangeValueInfoKey = @"RTSMediaPlaybackSegmentChangeValueInfoKey";
NSString * const RTSMediaPlaybackSegmentChangeUserSelectInfoKey = @"RTSMediaPlaybackSegmentChangeUserSelectInfoKey";

@interface RTSMediaSegmentsController ()
@property(nonatomic, strong) NSArray *segments;
@property(nonatomic, strong) id playerTimeObserver;
@property(nonatomic, weak) id<RTSMediaSegment> segmentBeingBlocked;
@property(nonatomic, weak) id<RTSMediaSegment> lastPlaybackPositionSegment;
@end

@implementation RTSMediaSegmentsController

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
	
    self.lastPlaybackPositionSegment = nil;
	self.segmentBeingBlocked = nil;
    
    RTSMediaSegmentsCompletionHandler reloadCompletionBlock = ^(NSArray *segments, NSError *error) {
        if (error) {
            if (completionHandler) {
                completionHandler(error);
            }
            return;
        }
        
        self.segments = [NSArray arrayWithArray:segments];
        
        [self addBlockingTimeObserver];
        
        if (completionHandler) {
            completionHandler(nil);
        }
    };
    
    [self.dataSource segmentsController:self segmentsForIdentifier:identifier withCompletionHandler:reloadCompletionBlock];
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
            if ([[segment segmentIdentifier] isEqualToString:self.playerController.identifier] && ![segment isFullLength]) {
				if (CMTimeRangeContainsTime(segment.timeRange, time)) {
					currentSegment = segment;
					*stop = YES;
				}
            }
        }];
        
        if (self.lastPlaybackPositionSegment != currentSegment) {
			NSDictionary *userInfo = nil;
			
			if (!currentSegment || (self.lastPlaybackPositionSegment && [currentSegment isBlocked])) {
				userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentEnd),
							 RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey: self.lastPlaybackPositionSegment,
							 RTSMediaPlaybackSegmentChangeUserSelectInfoKey: @(NO)};
			}
			else if (currentSegment && !self.lastPlaybackPositionSegment && ![currentSegment isBlocked]) {
				userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentStart),
							 RTSMediaPlaybackSegmentChangeSegmentInfoKey: currentSegment,
							 RTSMediaPlaybackSegmentChangeUserSelectInfoKey: @(NO)};
			}
			else if (currentSegment && self.lastPlaybackPositionSegment) {
				userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentSwitch),
							 RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey: self.lastPlaybackPositionSegment,
							 RTSMediaPlaybackSegmentChangeSegmentInfoKey: currentSegment,
							 RTSMediaPlaybackSegmentChangeUserSelectInfoKey: @(NO)};
			}
			
			if (userInfo) {
				[[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlaybackSegmentDidChangeNotification
																	object:self
																  userInfo:userInfo];
			}
			
			self.lastPlaybackPositionSegment = currentSegment;			
		}
		
		if ([currentSegment isBlocked]) {
			if (currentSegment == self.segmentBeingBlocked) {
				NSDictionary *userInfo = userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentSeekUponBlockingEnd),
													  RTSMediaPlaybackSegmentChangeSegmentInfoKey: currentSegment};
				
				[[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlaybackSegmentDidChangeNotification
																	object:self
																  userInfo:userInfo];
			}
			else {
				self.segmentBeingBlocked = currentSegment;
				// The reason for blocking must be specified, and should actually be accessible from the segment object, IMHO.
				
				NSDictionary *userInfo = userInfo = @{RTSMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentSeekUponBlockingStart),
													  RTSMediaPlaybackSegmentChangeSegmentInfoKey: currentSegment};
				
				[[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlaybackSegmentDidChangeNotification
																	object:self
																  userInfo:userInfo];
				
				[self.playerController seekToTime:CMTimeRangeGetEnd([currentSegment timeRange]) completionHandler:^(BOOL finished) {
					self.segmentBeingBlocked = nil;
				}];
			}
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
    return self.lastPlaybackPositionSegment;
}

- (void)playSegment:(id<RTSMediaSegment>)segment
{
    // Do not return if segment == currentSegment as we may want to restart the same segment.
    if (!segment || [segment isBlocked]) {
        return;
    }
    
    id<RTSMediaSegment> currentSegment = self.lastPlaybackPositionSegment;
    
    if ([[currentSegment segmentIdentifier] isEqualToString:[segment segmentIdentifier]]) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        userInfo[RTSMediaPlaybackSegmentChangeValueInfoKey] = @(RTSMediaPlaybackSegmentStart);
        userInfo[RTSMediaPlaybackSegmentChangeSegmentInfoKey] = segment;
        userInfo[RTSMediaPlaybackSegmentChangeUserSelectInfoKey] = @(YES); // <-- this is the reason for doing this here
        
        if (self.lastPlaybackPositionSegment) {
            userInfo[RTSMediaPlaybackSegmentChangePreviousSegmentInfoKey] = self.lastPlaybackPositionSegment;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlaybackSegmentDidChangeNotification
                                                            object:self
                                                          userInfo:[userInfo copy]];
        
        self.lastPlaybackPositionSegment = segment;
        
        [self.playerController seekToTime:segment.timeRange.start completionHandler:^(BOOL finished) {
            if (finished) {
                [self.playerController play];
            }
        }];
    }
    else {
        [self.playerController playIdentifier:[segment segmentIdentifier]];
    }
}

@end

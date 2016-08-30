//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <AVFoundation/AVFoundation.h>

#import <libextobjc/EXTScope.h>

#import "SRGMediaPlayerController.h"
#import "SRGMediaPlayerController+Private.h"
#import "RTSMediaSegment.h"
#import "RTSMediaSegmentsController.h"
#import "SRGMediaPlayerLogger.h"
#import "RTSMediaSegmentsDataSource.h"

NSTimeInterval const RTSMediaPlaybackTickInterval = 0.1;
NSString *const SRGMediaPlaybackSegmentDidChangeNotification = @"SRGMediaPlaybackSegmentDidChangeNotification";
NSString *const SRGMediaPlaybackSegmentChangeSegmentInfoKey = @"SRGMediaPlaybackSegmentChangeSegmentInfoKey";
NSString *const SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey = @"SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey";
NSString *const SRGMediaPlaybackSegmentChangeValueInfoKey = @"SRGMediaPlaybackSegmentChangeValueInfoKey";
NSString *const SRGMediaPlaybackSegmentChangeUserSelectInfoKey = @"SRGMediaPlaybackSegmentChangeUserSelectInfoKey";

@interface RTSMediaSegmentsController ()
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSArray *segments;
@property (nonatomic, strong) id playerTimeObserver;
@property (nonatomic, weak) id<RTSMediaSegment> lastPlaybackPositionLogicalSegment;
@property (nonatomic, strong) id segmentsRequestHandle;
@end

@implementation RTSMediaSegmentsController

- (void)setPlayerController:(SRGMediaPlayerController *)playerController
{
    _playerController = playerController;
    
    playerController.segmentsController = self;
}

- (void)reloadSegmentsForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSError *error))completionHandler
{
    NSParameterAssert(identifier);
    
    self.identifier = identifier;
    
    if (! self.playerController) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"Trying to reload data requires to have a player controller."
                                     userInfo:nil];
    }
    
    if (! self.dataSource) {
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
    
    if (! [self.identifier isEqualToString:identifier] && self.segmentsRequestHandle) {
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
        
        if (self.playerController.playbackState != SRGPlaybackStatePlaying) {
            return;
        }
        
        // We assume that all logical segments of a full length have an identifier that is IDENTICAL to the fullLength's.
        __block id<RTSMediaSegment> currentSegment = nil;
        [self.segments enumerateObjectsUsingBlock:^(id < RTSMediaSegment > segment, NSUInteger idx, BOOL *_Nonnull stop) {
            if ([segment.segmentIdentifier isEqualToString:self.playerController.identifier] && segment.logical) {
                if (CMTimeRangeContainsTime(segment.timeRange, time)) {
                    currentSegment = segment;
                    *stop = YES;
                }
            }
        }];
        
        if (self.lastPlaybackPositionLogicalSegment != currentSegment) {
            NSDictionary *userInfo = nil;
            
            if (! currentSegment || (self.lastPlaybackPositionLogicalSegment && currentSegment.blocked)) {
                userInfo = @{ SRGMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentEnd),
                              SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey: self.lastPlaybackPositionLogicalSegment,
                              SRGMediaPlaybackSegmentChangeUserSelectInfoKey: @(NO) };
            }
            else if (currentSegment && ! self.lastPlaybackPositionLogicalSegment && ! currentSegment.blocked) {
                userInfo = @{ SRGMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentStart),
                              SRGMediaPlaybackSegmentChangeSegmentInfoKey: currentSegment,
                              SRGMediaPlaybackSegmentChangeUserSelectInfoKey: @(NO) };
            }
            else if (currentSegment && self.lastPlaybackPositionLogicalSegment) {
                userInfo = @{ SRGMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentSwitch),
                              SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey: self.lastPlaybackPositionLogicalSegment,
                              SRGMediaPlaybackSegmentChangeSegmentInfoKey: currentSegment,
                              SRGMediaPlaybackSegmentChangeUserSelectInfoKey: @(NO) };
            }
            
            if (userInfo) {
                [[NSNotificationCenter defaultCenter] postNotificationName:SRGMediaPlaybackSegmentDidChangeNotification
                                                                    object:self
                                                                  userInfo:userInfo];
            }
            
            self.lastPlaybackPositionLogicalSegment = currentSegment;
        }
        
        // Managing blocked segments
        if (currentSegment.blocked) {
            NSDictionary *userInfo = userInfo = @{ SRGMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentSeekUponBlockingStart),
                                                   SRGMediaPlaybackSegmentChangeSegmentInfoKey: currentSegment };
            
            [[NSNotificationCenter defaultCenter] postNotificationName:SRGMediaPlaybackSegmentDidChangeNotification
                                                                object:self
                                                              userInfo:userInfo];
            
            [self.playerController seekToTime:CMTimeRangeGetEnd(currentSegment.timeRange) completionHandler:^(BOOL finished) {
                NSDictionary *userInfo = @{ SRGMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentSeekUponBlockingEnd),
                                            SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey: currentSegment };
                [[NSNotificationCenter defaultCenter] postNotificationName:SRGMediaPlaybackSegmentDidChangeNotification
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
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL (id < RTSMediaSegment > segment, NSDictionary < NSString *, id > *_Nullable bindings) {
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
        if (! self.lastPlaybackPositionLogicalSegment) {
            userInfo = @{ SRGMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentStart),
                          SRGMediaPlaybackSegmentChangeSegmentInfoKey: segment,
                          SRGMediaPlaybackSegmentChangeUserSelectInfoKey: @(YES) };
        }
        else {
            userInfo = @{ SRGMediaPlaybackSegmentChangeValueInfoKey: @(RTSMediaPlaybackSegmentSwitch),
                          SRGMediaPlaybackSegmentChangePreviousSegmentInfoKey: self.lastPlaybackPositionLogicalSegment,
                          SRGMediaPlaybackSegmentChangeSegmentInfoKey: segment,
                          SRGMediaPlaybackSegmentChangeUserSelectInfoKey: @(YES) };
        }
        
        // Immediately send the event. We thus also update the current segment information right here
        self.lastPlaybackPositionLogicalSegment = segment;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SRGMediaPlaybackSegmentDidChangeNotification
                                                            object:self
                                                          userInfo:userInfo];
    }
    else {
        self.lastPlaybackPositionLogicalSegment = nil;
    }
    
    if ([self.playerController.identifier isEqualToString:segment.segmentIdentifier]) {
        [self.playerController playAtTime:segment.timeRange.start];
    }
    else {
        [self.playerController playIdentifier:segment.segmentIdentifier];
    }
}

@end

@implementation SRGMediaPlayerController (RTSMediaSegmentsController)

@dynamic segmentsController;

@end

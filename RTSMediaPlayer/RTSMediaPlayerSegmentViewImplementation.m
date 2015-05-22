//
//  Created by Samuel Défago on 22.05.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSMediaPlayerSegmentViewImplementation.h"

#import "RTSMediaPlayerController.h"
#import "RTSMediaPlayerSegmentView.h"

static const NSTimeInterval RTSMediaPlayerSegmentDefaultReloadInterval = 30.;

@interface RTSMediaPlayerSegmentViewImplementation ()

@property (nonatomic, weak) UIView<RTSMediaPlayerSegmentView> *view;
@property (nonatomic, weak) id playbackTimeObserver;

@end

@implementation RTSMediaPlayerSegmentViewImplementation

#pragma mark - Object lifecycle

- (instancetype) initWithView:(UIView<RTSMediaPlayerSegmentView> *)view
{
	NSParameterAssert(view);
	
	if (self = [super init])
	{
		self.view = view;
		self.reloadInterval = RTSMediaPlayerSegmentDefaultReloadInterval;
	}
	return self;
}

#pragma mark - Getters and setters

- (void) setMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController
{
	if (_mediaPlayerController)
	{
		[_mediaPlayerController removePlaybackTimeObserver:self.playbackTimeObserver];
	}
	
	_mediaPlayerController = mediaPlayerController;
	
	self.playbackTimeObserver = [mediaPlayerController addPlaybackTimeObserverForInterval:CMTimeMakeWithSeconds(self.reloadInterval, 1.) queue:NULL usingBlock:^(CMTime time) {
		[self reloadSegments];
	}];
}

- (void) setReloadInterval:(NSTimeInterval)reloadInterval
{
	if (reloadInterval <= 0)
	{
		reloadInterval = RTSMediaPlayerSegmentDefaultReloadInterval;
	}
	_reloadInterval = reloadInterval;
}

#pragma mark - Data

- (void) reloadSegments
{
    [self.dataSource mediaPlayerSegmentView:self.view segmentsForIdentifier:self.mediaPlayerController.identifier completionHandler:^(NSArray *segments, NSError *error) {
        // FIXME: A retry mechanism should be implemented in case of failure
        
        // Sort segments in ascending order
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES comparator:^NSComparisonResult(NSValue *timeValue1, NSValue *timeValue2) {
            CMTime time1 = [timeValue1 CMTimeValue];
            CMTime time2 = [timeValue2 CMTimeValue];
            return CMTimeCompare(time1, time2);
        }];
        [self.view reloadWithSegments:[segments sortedArrayUsingDescriptors:@[sortDescriptor]]];
    }];
}

@end

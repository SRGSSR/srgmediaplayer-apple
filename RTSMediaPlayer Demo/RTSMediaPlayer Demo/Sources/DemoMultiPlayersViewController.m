//
//  Created by Frédéric Humbert-Droz on 10/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "DemoMultiPlayersViewController.h"
#import <RTSMediaPlayer/RTSMediaPlayerPlaybackButton.h>

@interface DemoMultiPlayersViewController ()

@property (nonatomic, strong) NSMutableArray *playerViews;
@property (nonatomic, strong) NSMutableArray *mediaPlayerControllers;

@property (nonatomic, assign) NSInteger selectedIndex;

@property (nonatomic, weak) IBOutlet UIView *mainPlayerView;
@property (nonatomic, weak) IBOutlet UIView *playerViewsContainer;

@property (nonatomic, weak) IBOutlet RTSMediaPlayerPlaybackButton *playPauseButton;
@property (nonatomic, weak) IBOutlet UISwitch *thumbnailSwitch;

@property (nonatomic, strong) IBOutletCollection(UIView) NSArray *overlayViews;

@end

@implementation DemoMultiPlayersViewController

#pragma mark - Accessors

- (void) setMediaURLs:(NSArray *)mediaURLs
{
	_mediaURLs = mediaURLs;
	
	self.mediaPlayerControllers = [NSMutableArray array];
	
	for (NSURL *mediaURL in mediaURLs)
	{
		RTSMediaPlayerController *mediaPlayerController = [[RTSMediaPlayerController alloc] initWithContentURL:mediaURL];
		UITapGestureRecognizer *switchTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchMainPlayer:)];
		[mediaPlayerController.view addGestureRecognizer:switchTapGestureRecognizer];
		[self.mediaPlayerControllers addObject:mediaPlayerController];
	}
}

#pragma mark - Lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	[self setSelectedIndex:0];
	[self play];
}

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[self.mediaPlayerControllers makeObjectsPerformSelector:@selector(reset)];
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
	{
		NSInteger index = 0;
		for (UIView *playerView in self.playerViewsContainer.subviews)
			playerView.frame = [self rectForPlayerViewAtIndex:index++];
	}
	completion:NULL];
}

#pragma mark - Action

- (void)play
{
	[self.mediaPlayerControllers makeObjectsPerformSelector:@selector(play)];
}

- (void)pause
{
	[self.mediaPlayerControllers makeObjectsPerformSelector:@selector(pause)];
}

- (IBAction) dismiss:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction) thumbnailSwitchDidChange:(UISwitch *)sender
{
	self.playerViewsContainer.hidden = !sender.isOn;

	dispatch_async(dispatch_get_main_queue(), ^{
		SEL action = sender.isOn ? @selector(play) : @selector(stop);
		[self.thumbnailPlayerControllers makeObjectsPerformSelector:action];
	});	
}

#pragma mark - Media Players

- (void) setSelectedIndex:(NSInteger)selectedIndex
{
	_selectedIndex = selectedIndex;
	
	RTSMediaPlayerController *mainMediaPlayerController = self.mediaPlayerControllers[selectedIndex];
	[self attachPlayer:mainMediaPlayerController toView:self.mainPlayerView];
	
	[self.playerViewsContainer.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[self.playerViewsContainer layoutIfNeeded];
	
	for (NSInteger index = 0; index<self.mediaPlayerControllers.count; index++)
	{
		if (index == selectedIndex)
			continue;

		CGRect playerViewFrame = [self rectForPlayerViewAtIndex:self.playerViewsContainer.subviews.count];
		UIView *playerView = [[UIView alloc] initWithFrame:playerViewFrame];
		playerView.backgroundColor = [UIColor blackColor];
		playerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
		[self.playerViewsContainer addSubview:playerView];
		
		RTSMediaPlayerController *thumbnailMediaPlayerController = self.mediaPlayerControllers[index];
		[self attachPlayer:thumbnailMediaPlayerController toView:playerView];
	}
}

- (CGRect) rectForPlayerViewAtIndex:(NSInteger)index
{
	CGFloat playerWidth = MAX(100, MIN(200, CGRectGetWidth(self.playerViewsContainer.frame) / (self.mediaURLs.count-1)));
	CGFloat playerHeight = (playerWidth-10)*10/16;
	
	CGFloat x = self.mediaURLs.count > 2 ? index * playerWidth : (CGRectGetWidth(self.playerViewsContainer.frame)-playerWidth)/2;
	CGFloat y = CGRectGetHeight(self.playerViewsContainer.frame)/2 - playerHeight/2;

	return CGRectMake(x+5, y, playerWidth-10, playerHeight);
}

- (void) attachPlayer:(RTSMediaPlayerController *)mediaPlayerController toView:(UIView *)playerView
{
	BOOL isMainPlayer = playerView == self.mainPlayerView;
	if (isMainPlayer) {
		[self.playPauseButton setMediaPlayerController:mediaPlayerController];
	}
	
	mediaPlayerController.overlayViews = isMainPlayer ? self.overlayViews : nil;
	[mediaPlayerController attachPlayerToView:playerView];
	[mediaPlayerController mute:!isMainPlayer];
	
	UITapGestureRecognizer *defaultTapGestureRecognizer = mediaPlayerController.view.gestureRecognizers.firstObject;
	UITapGestureRecognizer *switchTapGestureRecognizer = mediaPlayerController.view.gestureRecognizers.lastObject;
	defaultTapGestureRecognizer.enabled = isMainPlayer;
	switchTapGestureRecognizer.enabled = !isMainPlayer;
}

- (RTSMediaPlayerController *) mediaPlayerControllerForPlayerView:(UIView *)playerView
{
	for (RTSMediaPlayerController *mediaPlayerController in self.mediaPlayerControllers)
	{
		if ([mediaPlayerController.view isEqual:playerView])
			return mediaPlayerController;
	}
	
	return nil;
}

- (NSArray *) thumbnailPlayerControllers
{
	NSMutableArray *thumbnailPlayerControllers = [NSMutableArray array];
	for (RTSMediaPlayerController *mediaPlayerController in self.mediaPlayerControllers)
	{
		if (![mediaPlayerController.view.superview isEqual:self.mainPlayerView])
			[thumbnailPlayerControllers addObject:mediaPlayerController];
	}
	
	return [thumbnailPlayerControllers copy];
}

#pragma mark - Gestures

- (void) switchMainPlayer:(UITapGestureRecognizer *)gestureRecognizer
{
	RTSMediaPlayerController *mediaPlayerController = [self mediaPlayerControllerForPlayerView:gestureRecognizer.view];
	self.selectedIndex = [self.mediaPlayerControllers indexOfObject:mediaPlayerController];
}

@end

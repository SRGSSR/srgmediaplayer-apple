//
//  Created by Cédric Luthi on 25.02.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSMediaPlayerController.h"
#import "RTSMediaPlayerView.h"

#import <TransitionKit/TransitionKit.h>
#import <libextobjc/EXTScope.h>

NSString * const RTSMediaPlayerPlaybackDidFinishNotification = @"RTSMediaPlayerPlaybackDidFinish";
NSString * const RTSMediaPlayerPlaybackStateDidChangeNotification = @"RTSMediaPlayerPlaybackStateDidChange";
NSString * const RTSMediaPlayerNowPlayingMediaDidChangeNotification = @"RTSMediaPlayerNowPlayingMediaDidChange";
NSString * const RTSMediaPlayerReadyToPlayNotification = @"RTSMediaPlayerReadyToPlay";


NSString * const RTSMediaPlayerPlaybackDidFinishReasonUserInfoKey = @"Reason";
NSString * const RTSMediaPlayerPlaybackDidFinishErrorUserInfoKey = @"Error";

@interface RTSMediaPlayerController () <RTSMediaPlayerControllerDataSource>

@property (readonly) TKStateMachine *loadStateMachine;
@property (readwrite) TKState *idleState;
@property (readwrite) TKState *contentURLLoadedState;
@property (readwrite) TKEvent *loadContentURLEvent;
@property (readwrite) TKEvent *loadAssetEvent;
@property (readwrite) TKEvent *resetLoadStateMachineEvent;

@property (readwrite) RTSMediaPlaybackState playbackState;
@property (readwrite) AVPlayer *player;

@property (readonly) RTSMediaPlayerView *playerView;

@end

@implementation RTSMediaPlayerController

@synthesize player = _player;
@synthesize view = _view;
@synthesize playbackState = _playbackState;
@synthesize loadStateMachine = _loadStateMachine;

#pragma mark - Initialization

- (instancetype) init
{
	return [self initWithContentURL:[NSURL URLWithString:nil]];
}

- (instancetype) initWithContentURL:(NSURL *)contentURL
{
	return [self initWithContentIdentifier:contentURL.absoluteString dataSource:self];
}

- (instancetype) initWithContentIdentifier:(NSString *)identifier dataSource:(id<RTSMediaPlayerControllerDataSource>)dataSource
{
	if (!(self = [super init]))
		return nil;
	
	_identifier = identifier;
	_dataSource = dataSource;
	
	[self.loadStateMachine activate];
	
	return self;
}

- (void) dealloc
{
	[self stop];
	self.player = nil;
}

#pragma mark - RTSMediaPlayerControllerDataSource 

// Used when initialized with `initWithContentURL:`
- (void) mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController contentURLForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSURL *contentURL, NSError *error))completionHandler
{
	if (!identifier)
		@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Trying to play a media with a nil identifier." userInfo:nil];
	
	completionHandler([NSURL URLWithString:identifier], nil);
}

#pragma mark - Loading

static const NSString *ResultKey = @"Result";
static const NSString *ShouldPlayKey = @"ShouldPlay";

static NSDictionary * TransitionUserInfo(TKTransition *transition, id<NSCopying> key, id value)
{
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:transition.userInfo];
	userInfo[key] = value;
	return [userInfo copy];
}

- (TKStateMachine *) loadStateMachine
{
	if (_loadStateMachine)
		return _loadStateMachine;
	
	TKStateMachine *loadStateMachine = [TKStateMachine new];
	TKState *idle = [TKState stateWithName:@"Idle"];
	TKState *loadingContentURL = [TKState stateWithName:@"Loading Content URL"];
	TKState *contentURLLoaded = [TKState stateWithName:@"Content URL Loaded"];
	TKState *loadingAsset = [TKState stateWithName:@"Loading Asset"];
	TKState *assetLoaded = [TKState stateWithName:@"Asset Loaded"];
	[loadStateMachine addStates:@[ idle, loadingContentURL, contentURLLoaded, loadingAsset, assetLoaded ]];
	loadStateMachine.initialState = idle;
	
	TKEvent *loadContentURL = [TKEvent eventWithName:@"Load Content URL" transitioningFromStates:@[ idle ] toState:loadingContentURL];
	TKEvent *loadContentURLFailure = [TKEvent eventWithName:@"Load Content URL Failure" transitioningFromStates:@[ loadingContentURL ] toState:idle];
	TKEvent *loadContentURLSuccess = [TKEvent eventWithName:@"Load Content URL Success" transitioningFromStates:@[ loadingContentURL ] toState:contentURLLoaded];
	TKEvent *loadAsset = [TKEvent eventWithName:@"Load Asset" transitioningFromStates:@[ contentURLLoaded ] toState:loadingAsset];
	TKEvent *loadAssetFailure = [TKEvent eventWithName:@"Load Asset Failure" transitioningFromStates:@[ loadingAsset ] toState:contentURLLoaded];
	TKEvent *loadAssetSuccess = [TKEvent eventWithName:@"Load Asset Success" transitioningFromStates:@[ loadingAsset ] toState:assetLoaded];
	TKEvent *resetLoadStateMachine = [TKEvent eventWithName:@"Reset" transitioningFromStates:@[ loadingContentURL, contentURLLoaded, loadingAsset, assetLoaded ] toState:idle];
	
	[loadStateMachine addEvents:@[ loadContentURL, loadContentURLFailure, loadContentURLSuccess, loadAsset, loadAssetFailure, loadAssetSuccess, resetLoadStateMachine ]];
	
	@weakify(self)
	
	void (^postError)(TKState *, TKTransition *) = ^(TKState *state, TKTransition *transition) {
		@strongify(self)
		id result = transition.userInfo[ResultKey];
		if ([result isKindOfClass:[NSError class]])
			[self postPlaybackDidFinishNotification:RTSMediaFinishReasonPlaybackError error:result];
	};
	
	[loadingContentURL setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
		@strongify(self)
		if (!self.dataSource)
			@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"RTSMediaPlayerController dataSource can not be nil." userInfo:nil];
		
		self.playbackState = RTSMediaPlaybackStatePendingPlay;
		
		[self.dataSource mediaPlayerController:self contentURLForIdentifier:self.identifier completionHandler:^(NSURL *contentURL, NSError *error) {
			if (contentURL)
			{
				[self.loadStateMachine fireEvent:loadContentURLSuccess userInfo:TransitionUserInfo(transition, ResultKey, contentURL) error:NULL];
			}
			else if (error)
			{
				[self.loadStateMachine fireEvent:loadContentURLFailure userInfo:TransitionUserInfo(transition, ResultKey, error) error:NULL];
			}
			else
			{
				@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"The RTSMediaPlayerControllerDataSource implementation returned a nil contentURL and a nil error." userInfo:nil];
			}
		}];
	}];
	
	[loadingContentURL setDidExitStateBlock:postError];
	
	[contentURLLoaded setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
		@strongify(self)
		if (transition.sourceState == loadingContentURL)
			[self.loadStateMachine fireEvent:loadAsset userInfo:transition.userInfo error:NULL];
	}];
	
	[loadingAsset setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
		@strongify(self)
		NSURL *contentURL = transition.userInfo[ResultKey];
		AVURLAsset *asset = [AVURLAsset URLAssetWithURL:contentURL options:@{ AVURLAssetPreferPreciseDurationAndTimingKey: @(YES) }];
		static NSString *assetStatusKey = @"duration";
		[asset loadValuesAsynchronouslyForKeys:@[ assetStatusKey ] completionHandler:^{
			dispatch_async(dispatch_get_main_queue(), ^{
				NSError *valueStatusError = nil;
				AVKeyValueStatus status = [asset statusOfValueForKey:assetStatusKey error:&valueStatusError];
				if (status == AVKeyValueStatusLoaded)
				{
					[self.loadStateMachine fireEvent:loadAssetSuccess userInfo:TransitionUserInfo(transition, ResultKey, asset) error:NULL];
				}
				else
				{
					NSError *error = valueStatusError ?: [NSError errorWithDomain:@"XXX" code:0 userInfo:nil];
					[self.loadStateMachine fireEvent:loadAssetFailure userInfo:TransitionUserInfo(transition, ResultKey, error) error:NULL];
				}
			});
		}];
	}];
	
	[loadingAsset setDidExitStateBlock:postError];
	
	[assetLoaded setWillEnterStateBlock:^(TKState *state, TKTransition *transition) {
		@strongify(self)
		AVAsset *asset = transition.userInfo[ResultKey];
		self.player = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithAsset:asset]];
		[self.playerView setPlayer:self.player];
		[[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlayerReadyToPlayNotification object:self];
		if ([transition.userInfo[ShouldPlayKey] boolValue])
			[self.player play];
	}];
	
	[assetLoaded setWillExitStateBlock:^(TKState *state, TKTransition *transition) {
		@strongify(self)
		RTSMediaPlaybackState playbackState = self.playbackState;
		if (playbackState == RTSMediaPlaybackStatePlaying || playbackState == RTSMediaPlaybackStatePaused)
			[self postPlaybackDidFinishNotification:RTSMediaFinishReasonUserExited error:nil];
		
		self.playbackState = RTSMediaPlaybackStateEnded;
		
		[(RTSMediaPlayerView *)self.view setPlayer:nil];
		self.player = nil;
	}];
	
	self.idleState = idle;
	self.contentURLLoadedState = contentURLLoaded;
	self.loadContentURLEvent = loadContentURL;
	self.loadAssetEvent = loadAsset;
	self.resetLoadStateMachineEvent = resetLoadStateMachine;
	
	_loadStateMachine = loadStateMachine;
	
	return _loadStateMachine;
}

- (void) postPlaybackDidFinishNotification:(RTSMediaFinishReason)reason error:(NSError *)error
{
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	[userInfo setObject:@(reason) forKey:RTSMediaPlayerPlaybackDidFinishReasonUserInfoKey];
	
	if (error)
		[userInfo setObject:error forKey:RTSMediaPlayerPlaybackDidFinishErrorUserInfoKey];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlayerPlaybackDidFinishNotification object:self userInfo:userInfo];
}

#pragma mark - Playback

- (void) play
{
	if (self.player)
	{
		[self.player play];
	}
	else
	{
		[self loadAndPlay:YES];
	}
}

- (void) prepareToPlay
{
	[self loadAndPlay:NO];
}

- (void) loadAndPlay:(BOOL)shouldPlay
{
	NSDictionary *userInfo = @{ ShouldPlayKey: @(shouldPlay) };
	if ([self.loadStateMachine.currentState isEqual:self.idleState])
		[self.loadStateMachine fireEvent:self.loadContentURLEvent userInfo:userInfo error:NULL];
	else if ([self.loadStateMachine.currentState isEqual:self.contentURLLoadedState])
		[self.loadStateMachine fireEvent:self.loadAssetEvent userInfo:userInfo error:NULL];
}

- (void) playIdentifier:(NSString *)identifier
{
	if (![self.identifier isEqualToString:identifier])
	{
		self.identifier = identifier;
		[self.loadStateMachine fireEvent:self.resetLoadStateMachineEvent userInfo:nil error:NULL];
	}
	
	[self loadAndPlay:YES];
}

- (void) pause
{
	[self.player pause];
}

- (void) stop
{
	[self.loadStateMachine fireEvent:self.resetLoadStateMachineEvent userInfo:nil error:nil];
}

- (void) seekToTime:(NSTimeInterval)time
{
	[self.player seekToTime:CMTimeMakeWithSeconds(time, 1000) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:NULL];
}

- (RTSMediaPlaybackState) playbackState
{
	@synchronized(self)
	{
		return _playbackState;
	}
}

- (void) setPlaybackState:(RTSMediaPlaybackState)playbackState
{
	@synchronized(self)
	{
		if (_playbackState == playbackState)
			return;
		
		_playbackState = playbackState;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlayerPlaybackStateDidChangeNotification object:self userInfo:nil];
	}
}

#pragma mark - AVPlayer

static const void * const AVPlayerRateContext = &AVPlayerRateContext;

- (AVPlayer *) player
{
	@synchronized(self)
	{
		return _player;
	}
}

- (void) setPlayer:(AVPlayer *)player
{
	@synchronized(self)
	{
		[_player removeObserver:self forKeyPath:@"rate" context:(void *)AVPlayerRateContext];
		
		_player = player;
		
		[_player addObserver:self forKeyPath:@"rate" options:0 context:(void *)AVPlayerRateContext];
	}
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == AVPlayerRateContext)
	{
		BOOL paused = self.player.rate == 0.f;
		RTSMediaPlaybackState newState = paused ? RTSMediaPlaybackStatePaused : RTSMediaPlaybackStatePlaying;
		if (self.playbackState != newState)
			self.playbackState = newState;
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark - View

- (void) attachPlayerToView:(UIView *)containerView
{
	if (self.view.superview)
		[self.view removeFromSuperview];
	
	self.view.frame = CGRectMake(0, 0, CGRectGetWidth(containerView.bounds), CGRectGetHeight(containerView.bounds));
	[containerView insertSubview:self.view atIndex:0];
}

- (UIView *) view
{
	if (!_view)
	{
		_view = [RTSMediaPlayerView new];
		_view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		
		UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleOverlays)];
		UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleAspect)];
		doubleTapGestureRecognizer.numberOfTapsRequired = 2;
		[singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
		
		[_view addGestureRecognizer:singleTapGestureRecognizer];
		[_view addGestureRecognizer:doubleTapGestureRecognizer];
	}
	return _view;
}

- (RTSMediaPlayerView *) playerView
{
	return (RTSMediaPlayerView *)self.view;
}

#pragma mark - Overlays

- (void) toggleOverlays
{
	UIView *firstOverlayView = [self.overlayViews firstObject];
	if (!firstOverlayView || !self.playerView.playerLayer.isReadyForDisplay)
		return;
	
	BOOL hidden = !firstOverlayView.hidden;
	for (UIView *overlayView in self.overlayViews)
	{
		overlayView.hidden = hidden;
	}
}

#pragma mark - Resize Aspect

- (void) toggleAspect
{
	AVPlayerLayer *playerLayer = self.playerView.playerLayer;
	if (!playerLayer.isReadyForDisplay)
		return;
	
	if ([playerLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspect])
		playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	else
		playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
}

@end

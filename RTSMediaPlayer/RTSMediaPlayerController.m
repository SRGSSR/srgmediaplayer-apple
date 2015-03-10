//
//  Created by Cédric Luthi on 25.02.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSMediaPlayerController.h"
#import "RTSMediaPlayerView.h"

#import <TransitionKit/TransitionKit.h>

NSString * const RTSMediaPlayerPlaybackDidFinishNotification = @"RTSMediaPlayerPlaybackDidFinish";
NSString * const RTSMediaPlayerPlaybackStateDidChangeNotification = @"RTSMediaPlayerPlaybackStateDidChange";
NSString * const RTSMediaPlayerNowPlayingMediaDidChangeNotification = @"RTSMediaPlayerNowPlayingMediaDidChange";
NSString * const RTSMediaPlayerReadyToPlayNotification = @"RTSMediaPlayerReadyToPlay";


NSString * const RTSMediaPlayerPlaybackDidFinishReasonUserInfoKey = @"Reason";
NSString * const RTSMediaPlayerPlaybackDidFinishErrorUserInfoKey = @"Error";

@interface RTSMediaPlayerControllerURLDataSource : NSObject <RTSMediaPlayerControllerDataSource>
@end

@implementation RTSMediaPlayerControllerURLDataSource

- (void) mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController contentURLForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSURL *contentURL, NSError *error))completionHandler
{
	completionHandler([NSURL URLWithString:identifier], nil);
}

@end

@interface RTSMediaPlayerController ()

@property (readonly) TKStateMachine *loadStateMachine;
@property (readonly) TKState *noneState;
@property (readonly) TKState *contentURLLoadedState;
@property (readonly) TKEvent *loadContentURLEvent;
@property (readonly) TKEvent *loadAssetEvent;
@property (readonly) TKEvent *resetLoadStateMachineEvent;

@property (readwrite) RTSMediaPlaybackState playbackState;
@property (readwrite) AVPlayer *player;
@property (readwrite) UIView *view;

@property RTSMediaPlayerControllerURLDataSource *contentURLDataSource;

@end

@implementation RTSMediaPlayerController

- (instancetype) initWithContentURL:(NSURL *)contentURL
{
	_contentURLDataSource = [RTSMediaPlayerControllerURLDataSource new];
	return [self initWithContentIdentifier:contentURL.absoluteString dataSource:_contentURLDataSource];
}

- (instancetype) initWithContentIdentifier:(NSString *)identifier dataSource:(id<RTSMediaPlayerControllerDataSource>)dataSource
{
	if (!(self = [super init]))
		return nil;
	
	_identifier = identifier;
	_dataSource = dataSource;
	
	return self;
}

- (void) dealloc
{
	[self stop];
	self.player = nil;
}

@synthesize loadStateMachine = _loadStateMachine;

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
	TKState *none = [TKState stateWithName:@"None"];
	TKState *loadingContentURL = [TKState stateWithName:@"Loading Content URL"];
	TKState *contentURLLoaded = [TKState stateWithName:@"Content URL Loaded"];
	TKState *loadingAsset = [TKState stateWithName:@"Loading Asset"];
	TKState *assetLoaded = [TKState stateWithName:@"Asset Loaded"];
	[loadStateMachine addStates:@[ none, loadingContentURL, contentURLLoaded, loadingAsset, assetLoaded ]];
	loadStateMachine.initialState = none;
	
	TKEvent *loadContentURL = [TKEvent eventWithName:@"Load Content URL" transitioningFromStates:@[ none ] toState:loadingContentURL];
	TKEvent *loadContentURLFailure = [TKEvent eventWithName:@"Load Content URL Failure" transitioningFromStates:@[ loadingContentURL ] toState:none];
	TKEvent *loadContentURLSuccess = [TKEvent eventWithName:@"Load Content URL Success" transitioningFromStates:@[ loadingContentURL ] toState:contentURLLoaded];
	TKEvent *loadAsset = [TKEvent eventWithName:@"Load Asset" transitioningFromStates:@[ contentURLLoaded ] toState:loadingAsset];
	TKEvent *loadAssetFailure = [TKEvent eventWithName:@"Load Asset Failure" transitioningFromStates:@[ loadingAsset ] toState:contentURLLoaded];
	TKEvent *loadAssetSuccess = [TKEvent eventWithName:@"Load Asset Success" transitioningFromStates:@[ loadingAsset ] toState:assetLoaded];
	TKEvent *resetLoadStateMachine = [TKEvent eventWithName:@"Load Asset Success" transitioningFromStates:@[ loadingContentURL, contentURLLoaded, loadingAsset, assetLoaded ] toState:none];
	
	[loadStateMachine addEvents:@[ loadContentURL, loadContentURLFailure, loadContentURLSuccess, loadAsset, loadAssetFailure, loadAssetSuccess ]];

	__weak __typeof__(self) weakSelf = self;
	void (^postError)(TKState *, TKTransition *) = ^(TKState *state, TKTransition *transition) {
		id result = transition.userInfo[ResultKey];
		if ([result isKindOfClass:[NSError class]])
			[weakSelf postPlaybackDidFinishErrorNotification:result];
	};
	
	[loadingContentURL setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
		if (!weakSelf.dataSource)
			@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"RTSMediaPlayerController dataSource can not be nil." userInfo:nil];
		
		weakSelf.playbackState = RTSMediaPlaybackStatePendingPlay;
		
		[weakSelf.dataSource mediaPlayerController:weakSelf contentURLForIdentifier:weakSelf.identifier completionHandler:^(NSURL *contentURL, NSError *error) {
			if (contentURL)
			{
				[weakSelf.loadStateMachine fireEvent:loadContentURLSuccess userInfo:TransitionUserInfo(transition, ResultKey, contentURL) error:NULL];
			}
			else if (error)
			{
				[weakSelf.loadStateMachine fireEvent:loadContentURLFailure userInfo:TransitionUserInfo(transition, ResultKey, error) error:NULL];
			}
			else
			{
				@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"The RTSMediaPlayerControllerDataSource implementation returned a nil contentURL and a nil error." userInfo:nil];
			}
		}];
	}];
	
	[loadingContentURL setDidExitStateBlock:postError];
	
	[contentURLLoaded setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
		if (transition.sourceState == loadingContentURL)
			[weakSelf.loadStateMachine fireEvent:loadAsset userInfo:transition.userInfo error:NULL];
	}];
	
	[loadingAsset setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
		NSURL *contentURL = transition.userInfo[ResultKey];
		AVURLAsset *asset = [AVURLAsset URLAssetWithURL:contentURL options:@{ AVURLAssetPreferPreciseDurationAndTimingKey: @(YES) }];
		static NSString *assetStatusKey = @"duration";
		[asset loadValuesAsynchronouslyForKeys:@[ assetStatusKey ] completionHandler:^{
			dispatch_async(dispatch_get_main_queue(), ^{
				NSError *valueStatusError = nil;
				AVKeyValueStatus status = [asset statusOfValueForKey:assetStatusKey error:&valueStatusError];
				if (status == AVKeyValueStatusLoaded)
				{
					[weakSelf.loadStateMachine fireEvent:loadAssetSuccess userInfo:TransitionUserInfo(transition, ResultKey, asset) error:NULL];
				}
				else
				{
					NSError *error = valueStatusError ?: [NSError errorWithDomain:@"XXX" code:0 userInfo:nil];
					[weakSelf.loadStateMachine fireEvent:loadAssetFailure userInfo:TransitionUserInfo(transition, ResultKey, error) error:NULL];
				}
			});
		}];
	}];
	
	[loadingAsset setDidExitStateBlock:postError];
	
	[assetLoaded setWillEnterStateBlock:^(TKState *state, TKTransition *transition) {
		AVAsset *asset = transition.userInfo[ResultKey];
		weakSelf.player = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithAsset:asset]];
		[(RTSMediaPlayerView *)weakSelf.view setPlayer:weakSelf.player];
		[[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlayerReadyToPlayNotification object:weakSelf];
		if ([transition.userInfo[ShouldPlayKey] boolValue])
			[weakSelf.player play];
	}];
	
	[assetLoaded setWillExitStateBlock:^(TKState *state, TKTransition *transition) {
		RTSMediaPlaybackState playbackState = weakSelf.playbackState;
		if (playbackState == RTSMediaPlaybackStatePlaying || playbackState == RTSMediaPlaybackStatePaused)
			[weakSelf postPlaybackDidFinishNotification:RTSMediaFinishReasonUserExited error:nil];
		
		weakSelf.playbackState = RTSMediaPlaybackStateEnded;
		
		[(RTSMediaPlayerView *)weakSelf.view setPlayer:nil];
		weakSelf.player = nil;
	}];
	
	[loadStateMachine activate];
	
	_loadStateMachine = loadStateMachine;
	_noneState = none;
	_contentURLLoadedState = contentURLLoaded;
	_loadContentURLEvent = loadContentURL;
	_loadAssetEvent = loadAsset;
	_resetLoadStateMachineEvent = resetLoadStateMachine;
	
	return _loadStateMachine;
}

- (void) postPlaybackDidFinishErrorNotification:(NSError *)error
{
	[self postPlaybackDidFinishNotification:RTSMediaFinishReasonPlaybackError error:error];
}

- (void) postPlaybackDidFinishNotification:(RTSMediaFinishReason)reason error:(NSError *)error
{
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	[userInfo setObject:@(reason) forKey:RTSMediaPlayerPlaybackDidFinishReasonUserInfoKey];
	
	if (error)
		[userInfo setObject:error forKey:RTSMediaPlayerPlaybackDidFinishErrorUserInfoKey];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:RTSMediaPlayerPlaybackDidFinishNotification object:self userInfo:userInfo];
}

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
	if ([self.loadStateMachine.currentState isEqual:self.noneState])
		[self.loadStateMachine fireEvent:self.loadContentURLEvent userInfo:userInfo error:NULL];
	else if ([self.loadStateMachine.currentState isEqual:self.contentURLLoadedState])
		[self.loadStateMachine fireEvent:self.loadAssetEvent userInfo:userInfo error:NULL];
}

- (void) playIdentifier:(NSString *)identifier
{
	if (![_identifier isEqualToString:identifier])
	{
		_identifier = identifier;
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
	[_loadStateMachine fireEvent:self.resetLoadStateMachineEvent userInfo:nil error:nil];
}

- (void) seekToTime:(NSTimeInterval)time
{
	
}

@synthesize playbackState = _playbackState;

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

@synthesize player = _player;

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

- (void) attachPlayerToView:(UIView *)containerView
{
	if (self.view.superview)
		[self.view removeFromSuperview];

	if (!self.view)
		_view = [[RTSMediaPlayerView alloc] initWithFrame:CGRectZero];
	
	self.view.frame = CGRectMake(0, 0, CGRectGetWidth(containerView.bounds), CGRectGetHeight(containerView.bounds));
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.view.backgroundColor = containerView.backgroundColor;
	[containerView insertSubview:self.view atIndex:0];
}

- (void) showOverlays
{
	for (UIView<RTSOverlayViewProtocol> *view in self.overlayViews)
	{
		[view mediaPlayerController:self overlayHidden:NO];
	}
	
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void) hideOverlays
{
	for (UIView<RTSOverlayViewProtocol> *view in self.overlayViews)
	{
		[view mediaPlayerController:self overlayHidden:YES];
	}
	
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}


@end

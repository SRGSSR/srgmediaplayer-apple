//
//  ViewController.m
//  SRGMediaPlayer-temp-demo
//
//  Created by Samuel Défago on 25/08/16.
//  Copyright © 2016 SRG. All rights reserved.
//

#import "ViewController.h"

#import <SRGMediaPlayer/SRGMediaPlayer.h>

static void *s_kvoContext = &s_kvoContext;

@interface ViewController ()

@property (nonatomic) SRGMediaPlayerController *playerController;

@property (nonatomic, weak) IBOutlet SRGPlaybackActivityIndicatorView *playbackActivityIndicatorView;
@property (nonatomic, weak) IBOutlet SRGPlaybackButton *playerButton;
@property (nonatomic, weak) IBOutlet SRGTimeSlider *timeSlider;

@end

@implementation ViewController

- (void)dealloc
{
	self.playerController = nil;
}

- (void)setPlayerController:(SRGMediaPlayerController *)playerController
{
	if (_playerController) {
		[_playerController removeObserver:self forKeyPath:@"playbackState"];
        
		[[NSNotificationCenter defaultCenter] removeObserver:self name:SRGMediaPlayerPlaybackDidFailNotification object:_playerController];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:SRGMediaPlayerSegmentDidStartNotification object:_playerController];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:SRGMediaPlayerSegmentDidEndNotification object:_playerController];
	}
	
	_playerController = playerController;
	
	if (playerController) {
		[playerController addObserver:self forKeyPath:@"playbackState" options:0 context:s_kvoContext];
        
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(playbackDidFail:)
													 name:SRGMediaPlayerPlaybackDidFailNotification
												   object:playerController];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(segmentDidStart:)
                                                     name:SRGMediaPlayerSegmentDidStartNotification
                                                   object:playerController];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(segmentDidEnd:)
                                                     name:SRGMediaPlayerSegmentDidEndNotification
                                                   object:playerController];
	}
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.playerController = [[SRGMediaPlayerController alloc] init];
	self.playerButton.mediaPlayerController = self.playerController;
	self.playbackActivityIndicatorView.mediaPlayerController = self.playerController;
	self.timeSlider.mediaPlayerController = self.playerController;
	
	self.playerController.view.frame = self.view.bounds;
	self.playerController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view insertSubview:self.playerController.view atIndex:0];
	
	NSURL *URL = [NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"];
	[self.playerController prepareToPlayURL:URL atTime:CMTimeMakeWithSeconds(30, 1) withCompletionHandler:^(BOOL finished) {
        [self.playerController togglePlayPause];
    }];
}

- (IBAction)togglePlayPause:(id)sender
{
	[self.playerController togglePlayPause];
}

- (IBAction)seek:(id)sender
{
	[self.playerController seekToTime:CMTimeAdd(self.playerController.player.currentTime, CMTimeMakeWithSeconds(10, 1)) completionHandler:^(BOOL finished) {
		NSLog(@"Finished: %@", finished ? @"YES" : @"NO");
	}];
}

- (IBAction)openPlayerViewController:(id)sender
{
	NSURL *URL = [NSURL URLWithString:@"http://distribution.bbb3d.renderfarming.net/video/mp4/bbb_sunflower_1080p_30fps_normal.mp4"];
	SRGMediaPlayerViewController *mediaPlayerViewController = [[SRGMediaPlayerViewController alloc] initWithContentURL:URL];
	[self presentViewController:mediaPlayerViewController animated:YES completion:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
	if (context == s_kvoContext) {
		NSLog(@"Playback state = %@", @(self.playerController.playbackState));
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)playbackDidFail:(NSNotification *)notification
{
	NSError *error = notification.userInfo[SRGMediaPlayerErrorKey];
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
	[alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
	[self presentViewController:alertController animated:YES completion:nil];
}

- (void)segmentDidStart:(NSNotification *)notification
{
    NSLog(@"Segment did start");
}

- (void)segmentDidEnd:(NSNotification *)notification
{
    NSLog(@"Segment did stop");
}

@end

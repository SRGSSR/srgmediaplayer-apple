//
//  ViewController.m
//  RTSMediaPlayerSample
//
//  Created by Frédéric Humbert-Droz on 04/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "ViewController.h"
#import <RTSMediaPlayer/RTSMediaPlayer.h>

@interface ViewController ()

@end

@implementation ViewController

- (IBAction)touchButton:(id)sender
{
	//NSURL *url = [NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"];
	NSURL *url = [NSURL URLWithString:@"https://srgssruni9ch-lh.akamaihd.net/i/enc9uni_ch@191320/master.m3u8"];
	RTSMediaPlayerViewController *mediaPlayerViewController = [[RTSMediaPlayerViewController alloc] initWithContentURL:url];
	[self presentViewController:mediaPlayerViewController animated:YES completion:NULL];
}

@end

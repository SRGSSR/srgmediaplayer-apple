//
//  AppDelegate.m
//  SRGMediaPlayer-temp-demo
//
//  Created by Samuel Défago on 25/08/16.
//  Copyright © 2016 SRG. All rights reserved.
//

#import "AppDelegate.h"

#import <AVFoundation/AVFoundation.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];

    return YES;
}

@end

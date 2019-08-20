//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGNativeMediaPlayerViewController.h"

#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>

@interface SRGNativeMediaPlayerViewController ()

@property (nonatomic) SRGMediaPlayerController *controller;

@end

@implementation SRGNativeMediaPlayerViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.controller = [[SRGMediaPlayerController alloc] init];
        
        @weakify(self)
        [self.controller addObserver:self keyPath:@keypath(SRGMediaPlayerController.new, player) options:0 block:^(MAKVONotification *notification) {
            @strongify(self)
            self.player = self.controller.player;
        }];
    }
    return self;
}

@end

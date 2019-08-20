//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediasViewController.h"

#import "AdvancedPlayerViewController.h"
#import "InlinePlayerViewController.h"
#import "Media.h"
#import "MediaPlayer.h"
#import "MultiPlayerViewController.h"
#import "NSBundle+Demo.h"
#import "SegmentsPlayerViewController.h"
#import "SimplePlayerViewController.h"
#import "UIWindow+SRGMediaPlayer.h"

#import <AVKit/AVKit.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface MediasViewController () <AVPlayerViewControllerDelegate>

@property (nonatomic, copy) NSString *configurationFileName;

@property (nonatomic) NSArray<MediaPlayer *> *mediaPlayers;

@property (nonatomic) NSArray<Media *> *medias;
@property (nonatomic) NSIndexPath *selectedIndexPath;

@end

@implementation MediasViewController

#pragma mark Object lifecycle

- (instancetype)initWithTitle:(NSString *)title configurationFileName:(NSString *)configurationFileName mediaPlayerType:(MediaPlayerType)mediaPlayerType
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass(self.class) bundle:nil];
    MediasViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.title = title;
    viewController.configurationFileName = configurationFileName;
    
    switch (mediaPlayerType) {
        case MediaPlayerTypeStandard: {
            viewController.mediaPlayers = @[ [MediaPlayer mediaPlayerWithName:DemoNonLocalizedString(@"SRG Media Player") class:SRGNativeMediaPlayerViewController.class],
                                             [MediaPlayer mediaPlayerWithName:DemoNonLocalizedString(@"System") class:AVPlayerViewController.class],
                                             [MediaPlayer mediaPlayerWithName:DemoNonLocalizedString(@"Simple custom") class:SimplePlayerViewController.class],
                                             [MediaPlayer mediaPlayerWithName:DemoNonLocalizedString(@"Advanced custom") class:AdvancedPlayerViewController.class],
                                             [MediaPlayer mediaPlayerWithName:DemoNonLocalizedString(@"Inline custom") class:InlinePlayerViewController.class] ];
            break;
        }
            
        case MediaPlayerTypeSegments: {
            viewController.mediaPlayers = @[ [MediaPlayer mediaPlayerWithName:DemoNonLocalizedString(@"Player with segments support") class:SegmentsPlayerViewController.class] ];
            break;
        }
            
        case MediaPlayerTypeMulti: {
            viewController.mediaPlayers = @[ [MediaPlayer mediaPlayerWithName:DemoNonLocalizedString(@"Multi player") class:MultiPlayerViewController.class] ];
            break;
        }
    }
    
    return viewController;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
}

#pragma mark Media extraction

- (NSArray<Media *> *)medias
{
    if (! _medias) {
        NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:self.configurationFileName ofType:@"plist"];
        _medias = [Media mediasFromFileAtPath:filePath];
    }
    return _medias;
}

#pragma mark AVPlayerViewControllerDelegate protocol

- (void)playerViewController:(AVPlayerViewController *)playerViewController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    UIViewController *topViewController = UIApplication.sharedApplication.keyWindow.srg_topViewController;
    [topViewController presentViewController:playerViewController animated:YES completion:^{
        completionHandler(YES);
    }];
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 0 ? DemoNonLocalizedString(@"Medias") : DemoNonLocalizedString(@"Players");
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? self.medias.count : self.mediaPlayers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return [tableView dequeueReusableCellWithIdentifier:@"MediaCell"];
    }
    else {
        return [tableView dequeueReusableCellWithIdentifier:@"PlayerCell"];
    }
}

#pragma mark UITableViewDelegate protocoél

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        Media *media = self.medias[indexPath.row];
        cell.textLabel.text = media.name;
        cell.accessoryType = [indexPath isEqual:self.selectedIndexPath] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else {
        MediaPlayer *mediaPlayer = self.mediaPlayers[indexPath.row];
        cell.textLabel.text = mediaPlayer.name;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        self.selectedIndexPath = indexPath;
        [tableView reloadData];
    }
    else {
        Media *media = self.medias[self.selectedIndexPath.row];
        if (! media) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:DemoNonLocalizedString(@"Please select a media first") message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:DemoNonLocalizedString(@"OK") style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
            return;
        }
        
        MediaPlayer *mediaPlayer = self.mediaPlayers[indexPath.row];
        if (mediaPlayer.playerClass == AVPlayerViewController.class) {
            AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
            playerViewController.delegate = self;
            
            AVPlayer *player = [AVPlayer playerWithURL:media.URL];
            playerViewController.player = player;
            [player play];
            
            [self presentViewController:playerViewController animated:YES completion:nil];
        }
        else if (mediaPlayer.playerClass == SRGNativeMediaPlayerViewController.class) {
            SRGNativeMediaPlayerViewController *playerViewController = [[SRGNativeMediaPlayerViewController alloc] init];
            [playerViewController.controller playURL:media.URL];
            [self presentViewController:playerViewController animated:YES completion:nil];
        }
        else if (mediaPlayer.playerClass == SimplePlayerViewController.class) {
            SimplePlayerViewController *playerViewController = [[SimplePlayerViewController alloc] initWithMedia:media];
            playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:playerViewController animated:YES completion:nil];
        }
        else if (mediaPlayer.playerClass == AdvancedPlayerViewController.class) {
            AdvancedPlayerViewController *playerViewController = [[AdvancedPlayerViewController alloc] initWithMedia:media];
            playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:playerViewController animated:YES completion:nil];
        }
        else if (mediaPlayer.playerClass == InlinePlayerViewController.class) {
            InlinePlayerViewController *playerViewController = [[InlinePlayerViewController alloc] initWithMedia:media];
            playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
            [self.navigationController pushViewController:playerViewController animated:YES];
        }
        else if (mediaPlayer.playerClass == SegmentsPlayerViewController.class) {
            SegmentsPlayerViewController *playerViewController = [[SegmentsPlayerViewController alloc] initWithMedia:media];
            playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:playerViewController animated:YES completion:nil];
        }
        else if (mediaPlayer.playerClass == MultiPlayerViewController.class) {
            NSMutableArray *medias = [self.medias mutableCopy];
            [medias removeObject:media];
            [medias insertObject:media atIndex:0];
            
            MultiPlayerViewController *playerViewController = [[MultiPlayerViewController alloc] initWithMedias:[medias copy]];
            playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:playerViewController animated:YES completion:nil];
        }
    }
}

@end

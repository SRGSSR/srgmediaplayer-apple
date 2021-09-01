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
#import "SimplePlayerViewController.h"
#import "SegmentsPlayerViewController.h"
#import "UIApplication+Demo.h"
#import "UIWindow+Demo.h"

@import AVKit;
@import SRGMediaPlayer;

static NSMutableSet<AVPlayerViewController *> *s_playerViewControllers;

@interface MediasViewController () <SRGMediaPlayerViewControllerDelegate>

@property (nonatomic, copy) NSString *configurationFileName;

@property (nonatomic) NSArray<MediaPlayer *> *mediaPlayers;

@property (nonatomic) NSArray<Media *> *medias;
@property (nonatomic) NSIndexPath *selectedIndexPath;

@end

@implementation MediasViewController

#pragma mark Class methods

+ (void)addPlayerViewController:(AVPlayerViewController *)playerViewController
{
    if (! s_playerViewControllers) {
        s_playerViewControllers = [NSMutableSet set];
    }
    [s_playerViewControllers addObject:playerViewController];
}

+ (void)removePlayerViewController:(AVPlayerViewController *)playerViewController
{
    [s_playerViewControllers removeObject:playerViewController];
}

#pragma mark Object lifecycle

- (instancetype)initWithTitle:(NSString *)title configurationFileName:(NSString *)configurationFileName mediaPlayerType:(MediaPlayerType)mediaPlayerType
{
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        self.title = title;
        self.configurationFileName = configurationFileName;
        
        switch (mediaPlayerType) {
            case MediaPlayerTypeStandard: {
                self.mediaPlayers = @[ [MediaPlayer mediaPlayerWithName:NSLocalizedString(@"SRG Media Player", nil) class:SRGMediaPlayerViewController.class],
                                       [MediaPlayer mediaPlayerWithName:NSLocalizedString(@"System", nil) class:AVPlayerViewController.class],
                                       [MediaPlayer mediaPlayerWithName:NSLocalizedString(@"Simple custom", nil) class:SimplePlayerViewController.class],
                                       [MediaPlayer mediaPlayerWithName:NSLocalizedString(@"Advanced custom", nil) class:AdvancedPlayerViewController.class],
                                       [MediaPlayer mediaPlayerWithName:NSLocalizedString(@"Inline custom", nil) class:InlinePlayerViewController.class] ];
                break;
            }
                
            case MediaPlayerTypeSegments: {
                self.mediaPlayers = @[ [MediaPlayer mediaPlayerWithName:NSLocalizedString(@"Player with segments support", nil) class:SegmentsPlayerViewController.class] ];
                break;
            }
                
            case MediaPlayerTypeMulti: {
                self.mediaPlayers = @[ [MediaPlayer mediaPlayerWithName:NSLocalizedString(@"Multi player", nil) class:MultiPlayerViewController.class] ];
                break;
            }
        }
    }
    return self;
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

- (void)playerViewControllerWillStartPictureInPicture:(AVPlayerViewController *)playerViewController
{
    [MediasViewController addPlayerViewController:playerViewController];
    
    // Disable external playback while picture in picture is active. Transition does not work. Sound is still sent
    // to the AirPlay receiver.
    playerViewController.player.allowsExternalPlayback = NO;
}

- (void)playerViewController:(AVPlayerViewController *)playerViewController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    UIViewController *topViewController = UIApplication.sharedApplication.demo_mainWindow.demo_topViewController;
    [topViewController presentViewController:playerViewController animated:YES completion:^{
        completionHandler(YES);
    }];
}

- (void)playerViewControllerDidStopPictureInPicture:(AVPlayerViewController *)playerViewController
{
    playerViewController.player.allowsExternalPlayback = YES;
    
    [MediasViewController removePlayerViewController:playerViewController];
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 0 ? NSLocalizedString(@"Medias", nil) : NSLocalizedString(@"Players", nil);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? self.medias.count : self.mediaPlayers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const kCellIdentifier = @"BasicCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (! cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
    }
    
    return cell;
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
        cell.accessoryType = UITableViewCellAccessoryNone;
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
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Please select a media first", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil]];
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
        else if (mediaPlayer.playerClass == SRGMediaPlayerViewController.class) {
            SRGMediaPlayerViewController *playerViewController = [[SRGMediaPlayerViewController alloc] init];
            playerViewController.delegate = self;
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
            playerViewController.modalPresentationStyle = UIModalPresentationCustom;
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
            NSMutableArray *medias = self.medias.mutableCopy;
            [medias removeObject:media];
            [medias insertObject:media atIndex:0];
            
            MultiPlayerViewController *playerViewController = [[MultiPlayerViewController alloc] initWithMedias:medias.copy];
            playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:playerViewController animated:YES completion:nil];
        }
    }
}

@end

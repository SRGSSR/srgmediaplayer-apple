//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediasViewController.h"

#import "InlinePlayerViewController.h"
#import "MultiPlayerViewController.h"
#import "NSBundle+Demo.h"
#import "Segment.h"
#import "SegmentsPlayerViewController.h"
#import "TimeshiftPlayerViewController.h"

#import <AVKit/AVKit.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface MediasViewController ()

@property (nonatomic, copy) NSString *mediaFileName;
@property (nonatomic) NSArray *medias;
@property (nonatomic) NSIndexPath *selectedIndexPath;

@end

@implementation MediasViewController

#pragma mark Object lifecycle

- (instancetype)initWithMediaFileName:(NSString *)mediaFileName
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass(self.class) bundle:nil];
    MediasViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.mediaFileName = mediaFileName;
    return viewController;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
}

#pragma mark Plist configuration extraction

- (NSArray *)medias
{
    if (! _medias) {
        NSDictionary *mediaURLs = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:self.mediaFileName ofType:@"plist"]];
        _medias = mediaURLs[@"Medias"];
    }

    return _medias;
}

- (NSURL *)URLForMediaAtIndex:(NSInteger)index
{
    return [NSURL URLWithString:self.medias[index][@"url"]];
}

- (NSArray<NSURL *> *)secondaryURLsForMediaAtIndex:(NSInteger)index
{
    NSMutableArray<NSURL *> *urls = [NSMutableArray new];
    for (NSString *urlString in self.medias[index][@"secondaryUrls"]) {
        NSURL *url = [NSURL URLWithString:urlString];
        if (url) {
            [urls addObject:url];
        }
    }

    return [urls copy];
}

- (NSArray<Segment *> *)segmentsForMediaAtIndex:(NSInteger)index
{
    NSMutableArray<Segment *> *segments = [NSMutableArray array];
    for (NSDictionary *segmentDictionary in self.medias[index][@"segments"]) {
        Segment *segment = [[Segment alloc] initWithDictionary:segmentDictionary];
        [segments addObject:segment];
    }
    return [segments copy];
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 0 ? @"Choose Media:" : @"Choose Player:";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? self.medias.count : 6;
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
        NSDictionary *media = [self.medias objectAtIndex:indexPath.row];
        cell.textLabel.text = media[@"name"];
        cell.accessoryType = [indexPath isEqual:self.selectedIndexPath] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else {
        switch (indexPath.row) {
            case 0: {
                cell.textLabel.text = DemoNonLocalizedString(@"iOS media player");
                break;
            }
                
            case 1: {
                cell.textLabel.text = DemoNonLocalizedString(@"SRG media player");
                break;
            }
                
            case 2: {
                cell.textLabel.text = DemoNonLocalizedString(@"Inline SRG player");
                break;
            }
                
            case 3: {
                cell.textLabel.text = DemoNonLocalizedString(@"Custom SRG player with timeshift support");
                break;
            }
                
            case 4: {
                cell.textLabel.text = DemoNonLocalizedString(@"Custom SRG player with segment support");
                break;
            }
                
            case 5: {
                cell.textLabel.text = DemoNonLocalizedString(@"Multi player");
                break;
            }
                
            default: {
                break;
            }
        }
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
        NSURL *contentURL = [self URLForMediaAtIndex:self.selectedIndexPath.row];
        
        if (! contentURL) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Please select a media first" message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:DemoNonLocalizedString(@"OK") style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
            return;
        }
        
        switch (indexPath.row) {
            case 0: {
                AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
                AVPlayer *player = [AVPlayer playerWithURL:contentURL];
                playerViewController.player = player;
                [self presentViewController:playerViewController animated:YES completion:^{
                    [player play];
                }];
                break;
            }
                
            case 1: {
                SRGMediaPlayerViewController *mediaPlayerViewController = [[SRGMediaPlayerViewController alloc] init];
                [mediaPlayerViewController.controller playURL:contentURL];
                [self presentViewController:mediaPlayerViewController animated:YES completion:nil];
                break;
            }
                
            case 2: {
                InlinePlayerViewController *inlinePlayerViewController = [[InlinePlayerViewController alloc] initWithContentURL:contentURL];
                [self.navigationController pushViewController:inlinePlayerViewController animated:YES];
                break;
            }
                
            case 3: {
                TimeshiftPlayerViewController *timeshiftPlayerViewController = [[TimeshiftPlayerViewController alloc] initWithContentURL:contentURL];
                [self presentViewController:timeshiftPlayerViewController animated:YES completion:nil];
                break;
            }
                
            case 4: {
                NSArray<Segment *> *segments = [self segmentsForMediaAtIndex:self.selectedIndexPath.row];
                SegmentsPlayerViewController *segmentsPlayerViewController = [[SegmentsPlayerViewController alloc] initWithContentURL:contentURL segments:segments];
                [self presentViewController:segmentsPlayerViewController animated:YES completion:nil];
                break;
            }
                
            case 5: {
                NSMutableArray<NSURL *> *contentURLs = [NSMutableArray arrayWithObject:contentURL];
                NSArray<NSURL *> *secondaryURLs = [self secondaryURLsForMediaAtIndex:self.selectedIndexPath.row];
                if (secondaryURLs) {
                    [contentURLs addObjectsFromArray:secondaryURLs];
                }
                
                MultiPlayerViewController *multiPlayerViewController = [[MultiPlayerViewController alloc] initWithMediaURLs:[contentURLs copy]];
                [self presentViewController:multiPlayerViewController animated:YES completion:nil];
                break;
            }
                
            default: {
                break;
            }
        }
    }
}

@end

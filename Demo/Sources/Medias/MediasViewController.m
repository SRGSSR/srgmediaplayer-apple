//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediasViewController.h"

#import <MediaPlayer/MediaPlayer.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

#import "DemoInlineViewController.h"
#import "DemoMultiPlayersViewController.h"
#import "VideoTimeshiftPlayerViewController.h"

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

#pragma mark Getters and setters

- (NSArray *)medias
{
    if (! _medias) {
        NSDictionary *mediaURLs = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:self.mediaFileName ofType:@"plist"]];
        _medias = mediaURLs[@"Medias"];
    }

    return _medias;
}

- (NSURL *)URLForSelectedMedia
{
    if (! self.selectedIndexPath) {
        return nil;
    }

    NSDictionary *media = [self.medias objectAtIndex:self.selectedIndexPath.row];
    return [NSURL URLWithString:media[@"url"]];
}

- (NSArray *)URLsForSelectedMedia
{
    if (! self.selectedIndexPath) {
        return nil;
    }

    NSMutableArray *urls = [NSMutableArray new];
    NSDictionary *media = [self.medias objectAtIndex:self.selectedIndexPath.row];
    for (NSString *urlString in media[@"urls"]) {
        NSURL *url = [NSURL URLWithString:urlString];
        if (url) {
            [urls addObject:url];
        }
    }

    return [urls copy];
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
    return section == 0 ? self.medias.count : 3;
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
                cell.textLabel.text = @"iOS media player";
                break;
            }
                
            case 1: {
                cell.textLabel.text = @"SRG media player";
                break;
            }
                
            case 2: {
                cell.textLabel.text = @"Inline SRG media player";
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
        NSURL *contentURL = [self URLForSelectedMedia];
        
        if (! contentURL) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Please select a media first" message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
            return;
        }
        
        switch (indexPath.row) {
            case 0: {
                MPMoviePlayerViewController *moviePlayerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:contentURL];
                [self presentMoviePlayerViewControllerAnimated:moviePlayerViewController];
                break;
            }
                
            case 1: {
                SRGMediaPlayerViewController *mediaPlayerViewController = [[SRGMediaPlayerViewController alloc] initWithContentURL:contentURL];
                [self presentViewController:mediaPlayerViewController animated:YES completion:nil];
                break;
            }
                
            case 2: {
                DemoInlineViewController *inlineViewController = [[DemoInlineViewController alloc] initWithContentURL:contentURL];
                [self.navigationController pushViewController:inlineViewController animated:YES];
                break;
            }
                
            default: {
                break;
            }
        }
    }
}

@end

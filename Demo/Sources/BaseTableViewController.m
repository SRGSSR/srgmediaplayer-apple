//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "BaseTableViewController.h"

#import <MediaPlayer/MediaPlayer.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

#import "DemoInlineViewController.h"
#import "DemoMultiPlayersViewController.h"
#import "VideoTimeshiftPlayerViewController.h"

@interface BaseTableViewController ()

@property (nonatomic) NSArray *medias;
@property (nonatomic) NSIndexPath *selectedIndexPath;

@end

@implementation BaseTableViewController

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
}

#pragma mark Data

- (NSString *)mediaURLPath
{
    return nil;
}

- (NSString *)mediaURLKey
{
    return nil;
}

- (NSArray *)actionCellIdentifiers
{
    return nil;
}

- (NSArray *)media
{
    if (! _medias) {
        NSDictionary *mediaURLs = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:[self mediaURLPath] ofType:@"plist"]];
        _medias = mediaURLs[[self mediaURLKey]];
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

#pragma mark Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    return (self.selectedIndexPath != nil);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"DemoInline"]) {
        DemoInlineViewController *playerViewController = segue.destinationViewController;
        playerViewController.mediaURL = [self URLForSelectedMedia];
    }
    else if ([segue.identifier isEqualToString:@"DemoTimeshift"]) {
        VideoTimeshiftPlayerViewController *playerViewController = segue.destinationViewController;
        playerViewController.mediaURL = [self URLForSelectedMedia];
        playerViewController.tokenizeMediaURL = (self.selectedIndexPath.row == 2);
    }
    else if ([segue.identifier isEqualToString:@"DemoMultiPlayers"]) {
        DemoMultiPlayersViewController *playerViewController = segue.destinationViewController;
        playerViewController.mediaURLs = [self URLsForSelectedMedia];
    }
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
    return section == 0 ? self.medias.count : self.actionCellIdentifiers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return [self configureMediaCellAtIndexPath:indexPath];
    }
    else {
        return [self configureActionCellAtIndexPath:indexPath];
    }
}

#pragma mark UITableViewDelegate protocoél

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        self.selectedIndexPath = indexPath;
        [tableView reloadData];
    }
    else {
        NSString *identifier = self.actionCellIdentifiers[indexPath.row];
        NSURL *contentURL = [self URLForSelectedMedia];
        
        if (! contentURL) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please select a media" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else if ([identifier isEqualToString:@"CellDefaultIOS"]) {
            MPMoviePlayerViewController *moviePlayerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:contentURL];
            [self presentMoviePlayerViewControllerAnimated:moviePlayerViewController];
        }
        else if ([identifier isEqualToString:@"CellDefaultRTS"]) {
            SRGMediaPlayerViewController *mediaPlayerViewController = [[SRGMediaPlayerViewController alloc] initWithContentURL:contentURL];
            [self presentViewController:mediaPlayerViewController animated:YES completion:nil];
        }
    }
}

#pragma mark Cells

- (UITableViewCell *)configureMediaCellAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSDictionary *media = [self.medias objectAtIndex:indexPath.row];
    cell.textLabel.text = media[@"name"];
    cell.accessoryType = [indexPath isEqual:self.selectedIndexPath] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (UITableViewCell *)configureActionCellAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:self.actionCellIdentifiers[indexPath.row] forIndexPath:indexPath];
    if (indexPath.row < 3) {
        cell.textLabel.textColor = [UIColor colorWithRed:0.f green:0.5f blue:0.0f alpha:1.f];
    }
    else {
        cell.textLabel.textColor = [UIColor colorWithRed:0.7f green:0.48f blue:0.015f alpha:1.f];
    }
    return cell;
}

@end

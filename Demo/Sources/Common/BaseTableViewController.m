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

#pragma mark Object lifecycle

- (instancetype)init
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass(self.class) bundle:nil];
    return [storyboard instantiateInitialViewController];
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
}

#pragma mark Stubs

- (NSString *)mediaURLPath
{
    NSAssert(NO, @"Must be implemented by subclassers");
    return nil;
}

- (NSString *)mediaURLKey
{
    NSAssert(NO, @"Must be implemented by subclassers");
    return nil;
}

- (NSArray *)actionCellIdentifiers
{
    NSAssert(NO, @"Must be implemented by subclassers");
    return nil;
}

#pragma mark Getters and setters

- (NSArray *)medias
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
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Please select a media first" message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
        }
        else if ([identifier isEqualToString:@"iOSMediaPlayerCell"]) {
            MPMoviePlayerViewController *moviePlayerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:contentURL];
            [self presentMoviePlayerViewControllerAnimated:moviePlayerViewController];
        }
        else if ([identifier isEqualToString:@"SRGMediaPlayerCell"]) {
            SRGMediaPlayerViewController *mediaPlayerViewController = [[SRGMediaPlayerViewController alloc] initWithContentURL:contentURL];
            [self presentViewController:mediaPlayerViewController animated:YES completion:nil];
        }
    }
}

#pragma mark Cells

- (UITableViewCell *)configureMediaCellAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"MediaCell" forIndexPath:indexPath];
    NSDictionary *media = [self.medias objectAtIndex:indexPath.row];
    cell.textLabel.text = media[@"name"];
    cell.accessoryType = [indexPath isEqual:self.selectedIndexPath] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (UITableViewCell *)configureActionCellAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:self.actionCellIdentifiers[indexPath.row] forIndexPath:indexPath];
    if (indexPath.row < 3) {
        cell.textLabel.textColor = [UIColor colorWithRed:0.f green:0.5f blue:0.f alpha:1.f];
    }
    else {
        cell.textLabel.textColor = [UIColor colorWithRed:0.7f green:0.48f blue:0.015f alpha:1.f];
    }
    return cell;
}

@end

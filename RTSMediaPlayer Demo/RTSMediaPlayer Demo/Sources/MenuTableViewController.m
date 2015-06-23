//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "MenuTableViewController.h"

#import <MediaPlayer/MediaPlayer.h>
#import <SRGMediaPlayer/RTSMediaPlayer.h>

#import "DemoInlineViewController.h"
#import "DemoMultiPlayersViewController.h"

@interface MenuTableViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSArray *media;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@end

@implementation MenuTableViewController

- (void) viewDidLoad
{
	[super viewDidLoad];
	self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
}



#pragma mark - Data

- (NSString *) mediaURLPath
{
	return nil;
}

- (NSString *) mediaURLKey
{
	return nil;
}

- (NSArray *) actionCellIdentifiers
{
	return nil;
}

- (NSArray *) media
{
	if (!_media){
		NSDictionary *mediaURLs = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:[self mediaURLPath] ofType:@"plist"]];
		_media = mediaURLs[[self mediaURLKey]];
	}
	
	return _media;
}

- (NSURL *) URLForSelectedMedia
{
	if (!self.selectedIndexPath)
		return nil;
		
	NSDictionary *media = [self.media objectAtIndex:self.selectedIndexPath.row];
	return [NSURL URLWithString:media[@"url"]];
}

- (NSArray *) URLsForSelectedMedia
{
	if (!self.selectedIndexPath)
		return nil;
	
	NSMutableArray *urls = [NSMutableArray new];
	NSDictionary *media = [self.media objectAtIndex:self.selectedIndexPath.row];
	for (NSString *urlString in media[@"urls"]) {
		NSURL *url = [NSURL URLWithString:urlString];
		if (url) {
			[urls addObject:url];
		}
	}
	
	return [urls copy];
}



#pragma mark - Navigation

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
	return (self.selectedIndexPath != nil);
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"DemoInline"])
	{
		DemoInlineViewController *demoInlineViewController = segue.destinationViewController;
		demoInlineViewController.mediaURL = [self URLForSelectedMedia];
	}
	else if ([segue.identifier isEqualToString:@"DemoMultiPlayers"])
	{
		DemoMultiPlayersViewController *demoMultiPlayerViewController = segue.destinationViewController;
		demoMultiPlayerViewController.mediaURLs = [self URLsForSelectedMedia];
	}
}



#pragma mark - UITableViewDataSource

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
	return section == 0 ? self.media.count : self.actionCellIdentifiers.count;
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

#pragma mark Cells

- (UITableViewCell *)configureMediaCellAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	
	NSDictionary *media = [self.media objectAtIndex:indexPath.row];
	cell.textLabel.text = media[@"name"];
	cell.accessoryType = [indexPath isEqual:self.selectedIndexPath] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	
	return cell;
}

- (UITableViewCell *)configureActionCellAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:self.actionCellIdentifiers[indexPath.row] forIndexPath:indexPath];
	if (indexPath.row < 3) {
		cell.textLabel.textColor = [UIColor colorWithRed:0.0 green:0.5 blue:0.0 alpha:1.0];
	}
	else {
		cell.textLabel.textColor = [UIColor colorWithRed:0.700 green:0.408 blue:0.015 alpha:1.000];
	}
	return cell;
}



#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (indexPath.section == 0)
	{
		self.selectedIndexPath = indexPath;
		[tableView reloadData];
	}
	else
	{
		NSString *identifier = self.actionCellIdentifiers[indexPath.row];
		
		NSURL *contentURL = [self URLForSelectedMedia];
		if (!contentURL)
		{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please select a media" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
			
		}else if ([identifier isEqualToString:@"CellDefaultIOS"])
		{
			MPMoviePlayerViewController *moviePlayerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:contentURL];
			[self presentMoviePlayerViewControllerAnimated:moviePlayerViewController];
		}
		else if ([identifier isEqualToString:@"CellDefaultRTS"])
		{
			RTSMediaPlayerViewController *mediaPlayerViewController = [[RTSMediaPlayerViewController alloc] initWithContentURL:contentURL];
			[self presentViewController:mediaPlayerViewController animated:YES completion:nil];
		}
	}
}

@end

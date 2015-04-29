//
//  Created by Cédric Luthi on 26.02.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "MenuTableViewController.h"

#import <MediaPlayer/MediaPlayer.h>
#import <RTSMediaPlayer/RTSMediaPlayer.h>

#import "DemoInlineViewController.h"
#import "DemoMultiPlayersViewController.h"

@interface MenuTableViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSArray *movies;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@end

@implementation MenuTableViewController

- (void) viewDidLoad
{
	[super viewDidLoad];
	self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
}



#pragma mark - Data

- (NSArray *) movies
{
	if (!_movies){
		NSDictionary *mediaURLs = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:@"MediaURLs" ofType:@"plist"]];
		_movies = mediaURLs[@"Movies"];
	}
	
	return _movies;
}

- (NSURL *) URLForSelectedMedia
{
	if (!self.selectedIndexPath)
		return nil;
		
	NSDictionary *media = [self.movies objectAtIndex:self.selectedIndexPath.row];
	return [NSURL URLWithString:media[@"url"]];
}

- (NSArray *) actionCellIdentifiers
{
	return @[ @"CellDefaultIOS",
			  @"CellDefaultRTS",
			  @"CellInline",
			  @"CellFullscreen",
			  @"CellMultiPlayers",
			  @"CellTimeline" ];
}



#pragma mark - Navigation

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
	return (self.selectedIndexPath != nil);
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	NSURL *mediaURL= [self URLForSelectedMedia];
	if ([segue.identifier isEqualToString:@"DemoInline"])
	{
		DemoInlineViewController *demoInlineViewController = segue.destinationViewController;
		demoInlineViewController.mediaURL = mediaURL;
	}
	else if ([segue.identifier isEqualToString:@"DemoMultiPlayers"])
	{
		DemoMultiPlayersViewController *demoMultiPlayerViewController = segue.destinationViewController;
		demoMultiPlayerViewController.mediaURLs = @[
                                                     [NSURL URLWithString:@"https://srgssruni9ch-lh.akamaihd.net/i/enc9uni_ch@191320/master.m3u8"], //RTS 1
                                                     [NSURL URLWithString:@"https://srgssruni10ch-lh.akamaihd.net/i/enc10uni_ch@191367/master.m3u8"], // RTS 2
                                                     [NSURL URLWithString:@"https://srgssruni7ch-lh.akamaihd.net/i/enc7uni_ch@191283/master.m3u8"], // WEB STREAM
                                                     [NSURL URLWithString:@"https://srgssruni11ch-lh.akamaihd.net/i/enc11uni_ch@191455/master.m3u8"], // RTS en continu
												  ];
	}
}



#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return section == 0 ? @"Media" : @"Actions";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return section == 0 ? self.movies.count : self.actionCellIdentifiers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0)
		return [self configureMediaCellAtIndexPath:indexPath];
	else
		return [self configureActionCellAtIndexPath:indexPath];
}

#pragma mark Cells

- (UITableViewCell *) configureMediaCellAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	
	NSDictionary *media = [self.movies objectAtIndex:indexPath.row];
	cell.textLabel.text = media[@"name"];
	cell.accessoryType = [indexPath isEqual:self.selectedIndexPath] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	
	return cell;
}

- (UITableViewCell *) configureActionCellAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:self.actionCellIdentifiers[indexPath.row] forIndexPath:indexPath];
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

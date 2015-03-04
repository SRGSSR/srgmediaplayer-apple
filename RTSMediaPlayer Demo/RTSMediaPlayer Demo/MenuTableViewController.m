//
//  Created by Cédric Luthi on 26.02.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "MenuTableViewController.h"

#import "DemoInlineViewController.h"

@implementation MenuTableViewController

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section != 0)
		return;
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	for (NSUInteger i = 0; i < [tableView.dataSource tableView:tableView numberOfRowsInSection:indexPath.section]; i++)
	{
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
		cell.accessoryType = indexPath.row == i ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	}
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	NSArray *contentURLStrings = @[ @"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8",
	                                @"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8",
	                                @"http://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_640x360.m4v",
	                                @"http://distribution.bbb3d.renderfarming.net/video/mp4/bbb_sunflower_1080p_30fps_normal.mp4" ];
	NSURL *mediaURL;
	for (NSUInteger i = 0; i < [self.tableView.dataSource tableView:self.tableView numberOfRowsInSection:0]; i++)
	{
		UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
		if (cell.accessoryType == UITableViewCellAccessoryCheckmark)
		{
			mediaURL = [NSURL URLWithString:contentURLStrings[i]];
			break;
		}
	}
	
	if ([segue.identifier isEqualToString:@"DemoInline"])
	{
		DemoInlineViewController *demoInlineViewController = segue.destinationViewController;
		demoInlineViewController.mediaURL = mediaURL;
	}
}

@end

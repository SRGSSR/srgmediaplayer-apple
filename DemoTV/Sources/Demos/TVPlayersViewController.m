//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "TVPlayersViewController.h"

#import "TVMediasViewController.h"

@implementation TVPlayersViewController

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self displayMediasForPlayerWithType:TVMediaPlayerTypeSystem];
}

#pragma mark Helpers

- (void)displayMediasForPlayerWithType:(TVMediaPlayerType)mediaPlayerType
{
    TVMediasViewController *mediasViewController = [[TVMediasViewController alloc] initWithConfigurationFileName:@"VideoDemoConfiguration" mediaPlayerType:mediaPlayerType];
    [self.splitViewController showDetailViewController:mediasViewController sender:nil];
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // UITableViewController on tvOS does not support static or dynamic table views defined in a storyboard,
    // apparently
    static NSString * const kCellIdentifier = @"PlayerCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (! cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
    }
    
    return cell;
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0: {
            cell.textLabel.text = NSLocalizedString(@"System player", nil);
            break;
        }
            
        case 1: {
            cell.textLabel.text = NSLocalizedString(@"SRG Media Player", nil);
            break;
        }
            
        default: {
            break;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
        case 0: {
            [self displayMediasForPlayerWithType:TVMediaPlayerTypeSystem];
            break;
        }
            
        case 1: {
            [self displayMediasForPlayerWithType:TVMediaPlayerTypeStandard];
            break;
        }
            
        default: {
            
            break;
        }
    }
}

@end

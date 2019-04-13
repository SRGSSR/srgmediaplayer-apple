//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "TVMediasViewController.h"

#import "Media.h"
#import "TVPlayerViewController.h"

@interface TVMediasViewController ()

@property (nonatomic, copy) NSString *configurationFileName;
@property (nonatomic) TVMediaPlayerType mediaPlayerType;

@property (nonatomic) NSArray<Media *> *medias;

@end

@implementation TVMediasViewController

#pragma mark Object lifecycle

- (instancetype)initWithConfigurationFileName:(NSString *)configurationFileName mediaPlayerType:(TVMediaPlayerType)mediaPlayerType
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass(self.class) bundle:nil];
    TVMediasViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.configurationFileName = configurationFileName;
    viewController.mediaPlayerType = mediaPlayerType;
    return viewController;
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

#pragma mark UITableViewDataSource protocol

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.medias.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // UITableViewController on tvOS does not support static or dynamic table views defined in a storyboard,
    // apparently
    static NSString * const kCellIdentifier = @"MediaCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (! cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
    }
    
    return cell;
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.text = self.medias[indexPath.row].name;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Media *media = self.medias[indexPath.row];
    
    switch (self.mediaPlayerType) {
        case TVMediaPlayerTypeSystem: {
            AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
            AVPlayer *player = [AVPlayer playerWithURL:media.URL];
            playerViewController.player = player;
            [self presentViewController:playerViewController animated:YES completion:^{
                [player play];
            }];
            break;
        }
            
        case TVMediaPlayerTypeStandard: {
            TVPlayerViewController *playerViewController = [[TVPlayerViewController alloc] initWithMedia:media];
            [self presentViewController:playerViewController animated:YES completion:nil];
            break;
        }
            
        default: {
            break;
        }
    }

}

@end

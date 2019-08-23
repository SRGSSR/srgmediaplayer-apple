//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "TVMediasViewController.h"

#import "Media.h"
#import "TVPlayerViewController.h"

static NSString * const kMediaKey = @"Media";

@interface TVMediasViewController () <SRGMediaPlayerViewControllerDelegate>

@property (nonatomic, copy) NSString *configurationFileName;

@property (nonatomic) NSArray<Media *> *medias;

@end

@implementation TVMediasViewController

#pragma mark Object lifecycle

- (instancetype)initWithConfigurationFileName:(NSString *)configurationFileName
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass(self.class) bundle:nil];
    TVMediasViewController *viewController = [storyboard instantiateInitialViewController];
    viewController.configurationFileName = configurationFileName;
    viewController.tableView.remembersLastFocusedIndexPath = YES;
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
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Player", nil) message:NSLocalizedString(@"Choose the player to play the media with", nil) preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"SRG Media Player", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        SRGMediaPlayerViewController *playerViewController = [[SRGMediaPlayerViewController alloc] init];
        playerViewController.delegate = self;
        [playerViewController.controller playURL:media.URL atPosition:nil withSegments:media.segments userInfo:@{ kMediaKey : media }];
        [self presentViewController:playerViewController animated:YES completion:nil];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"System player", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
        AVPlayer *player = [AVPlayer playerWithURL:media.URL];
        playerViewController.player = player;
        [self presentViewController:playerViewController animated:YES completion:^{
            [player play];
        }];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Simple player", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        TVPlayerViewController *playerViewController = [[TVPlayerViewController alloc] initWithMedia:media];
        [self presentViewController:playerViewController animated:YES completion:nil];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark SRGMediaPlayerViewControllerDelegate protocol

- (NSArray<AVMetadataItem *> *)playerViewControllerExternalMetadata:(SRGMediaPlayerViewController *)playerViewController
{
    Media *media = playerViewController.controller.userInfo[kMediaKey];
    if (! media) {
        return nil;
    }
    
    AVMutableMetadataItem *titleItem = [[AVMutableMetadataItem alloc] init];
    titleItem.identifier = AVMetadataCommonIdentifierTitle;
    titleItem.value = media.name;
    titleItem.extendedLanguageTag = @"und";
    
    AVMutableMetadataItem *artworkItem = [[AVMutableMetadataItem alloc] init];
    artworkItem.identifier = AVMetadataCommonIdentifierArtwork;
    artworkItem.value = UIImagePNGRepresentation([UIImage imageNamed:@"artwork"]);
    artworkItem.extendedLanguageTag = @"und";
    
    return @[ titleItem, artworkItem ];
}

- (NSArray<AVTimedMetadataGroup *> *)playerViewController:(SRGMediaPlayerViewController *)playerViewController navigationMarkersForSegments:(NSArray<id<SRGSegment>> *)segments
{
    NSMutableArray<AVTimedMetadataGroup *> *navigationMarkers = [NSMutableArray array];
    
    for (MediaSegment *segment in segments) {
        AVMutableMetadataItem *titleItem = [[AVMutableMetadataItem alloc] init];
        titleItem.identifier = AVMetadataCommonIdentifierTitle;
        titleItem.value = segment.name;
        titleItem.extendedLanguageTag = @"und";
        
        AVMutableMetadataItem *artworkItem = [[AVMutableMetadataItem alloc] init];
        artworkItem.identifier = AVMetadataCommonIdentifierArtwork;
        artworkItem.value = UIImagePNGRepresentation([UIImage imageNamed:@"artwork"]);
        artworkItem.extendedLanguageTag = @"und";
        
        AVTimedMetadataGroup *navigationMarker = [[AVTimedMetadataGroup alloc] initWithItems:@[ titleItem.copy, artworkItem.copy ] timeRange:segment.srg_timeRange];
        [navigationMarkers addObject:navigationMarker];
    }
    
    return navigationMarkers.copy;
}

@end


//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediasViewController.h"

#import "Media.h"
#import "SimplePlayerViewController.h"
#import "UIApplication+Demo.h"
#import "UIWindow+Demo.h"

static NSString * const kMediaKey = @"Media";

static NSMutableSet<AVPlayerViewController *> *s_playerViewControllers;

@interface MediasViewController () <SRGMediaPlayerViewControllerDelegate>

@property (nonatomic, copy) NSString *configurationFileName;
@property (nonatomic) MediaPlayerType mediaPlayerType;

@property (nonatomic) NSArray<Media *> *medias;

@end

@implementation MediasViewController

#pragma mark Class methods

+ (void)addPlayerViewController:(AVPlayerViewController *)playerViewController
{
    if (! s_playerViewControllers) {
        s_playerViewControllers = [NSMutableSet set];
    }
    [s_playerViewControllers addObject:playerViewController];
}

+ (void)removePlayerViewController:(AVPlayerViewController *)playerViewController
{
    [s_playerViewControllers removeObject:playerViewController];
}

#pragma mark Object lifecycle

- (instancetype)initWithTitle:(NSString *)title configurationFileName:(NSString *)configurationFileName mediaPlayerType:(MediaPlayerType)mediaPlayerType
{
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        self.title = title;
        self.configurationFileName = configurationFileName;
        self.mediaPlayerType = mediaPlayerType;
    }
    return self;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (@available(tvOS 13, *)) {
        self.navigationController.tabBarObservedScrollView = self.tableView;
    }
    
    self.tableView.remembersLastFocusedIndexPath = YES;
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
    static NSString * const kCellIdentifier = @"BasicCell";
    
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
        playerViewController.delegate = self;
        AVPlayer *player = [AVPlayer playerWithURL:media.URL];
        playerViewController.player = player;
        [self presentViewController:playerViewController animated:YES completion:^{
            [player play];
        }];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Simple player", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        SimplePlayerViewController *playerViewController = [[SimplePlayerViewController alloc] initWithMedia:media];
        [self presentViewController:playerViewController animated:YES completion:nil];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark AVPlayerViewControllerDelegate protocol

- (void)playerViewControllerWillStartPictureInPicture:(AVPlayerViewController *)playerViewController
{
    [MediasViewController addPlayerViewController:playerViewController];
}

- (void)playerViewControllerDidStopPictureInPicture:(AVPlayerViewController *)playerViewController
{
    [MediasViewController removePlayerViewController:playerViewController];
}

- (void)playerViewController:(AVPlayerViewController *)playerViewController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    void (^presentPlayer)(void) = ^{
        // Do not animate on tvOS to avoid UI glitches when swapping
        [self presentViewController:playerViewController animated:NO completion:^{
            completionHandler(YES);
        }];
    };
    
    // On tvOS dismiss any existing player first, otherwise picture in picture will be stopped when swapping
    UIViewController *topViewController = UIApplication.sharedApplication.demo_mainWindow.demo_topViewController;
    if ([topViewController isKindOfClass:AVPlayerViewController.class]) {
        [topViewController dismissViewControllerAnimated:NO completion:presentPlayer];
    }
    else {
        presentPlayer();
    }
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
    
    return @[ titleItem.copy, artworkItem.copy ];
}

- (NSArray<AVTimedMetadataGroup *> *)playerViewController:(SRGMediaPlayerViewController *)playerViewController navigationMarkersForSegments:(NSArray<id<SRGSegment>> *)segments
{
    if (self.mediaPlayerType == MediaPlayerTypeSegments) {
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
            
            CMTimeRange segmentTimeRange = [segment.srg_markRange timeRangeForMediaPlayerController:playerViewController.controller];
            AVTimedMetadataGroup *navigationMarker = [[AVTimedMetadataGroup alloc] initWithItems:@[ titleItem.copy, artworkItem.copy ] timeRange:segmentTimeRange];
            [navigationMarkers addObject:navigationMarker];
        }
        return navigationMarkers.copy;
    }
    else {
        return nil;
    }
}

@end


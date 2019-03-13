//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//
#import "SRGAlternateTracksViewController.h"

#import "NSBundle+SRGMediaPlayer.h"

#import <MediaAccessibility/MediaAccessibility.h>

static NSString *SRGTitleForMediaOption(AVMediaSelectionOption *option);

@interface SRGAlternateTracksViewController ()

@property (nonatomic) NSArray<NSString *> *characteristics;
@property (nonatomic) NSDictionary<NSString *, AVMediaSelectionGroup *> *selectionGroups;

@property (nonatomic) AVPlayer *player;

@end

@implementation SRGAlternateTracksViewController

@synthesize delegate = _delegate;
@synthesize player = _player;

#pragma mark Class methods

+ (UINavigationController *)alternateTracksNavigationControllerForPlayer:(AVPlayer *)player withDelegate:(id<SRGAlternateTracksViewControllerDelegate>)delegate
{
    SRGAlternateTracksViewController *alternateTracksViewController = [[SRGAlternateTracksViewController alloc] initWithStyle:UITableViewStyleGrouped];
    alternateTracksViewController.delegate = delegate;
    alternateTracksViewController.player = player;
    return [[UINavigationController alloc] initWithRootViewController:alternateTracksViewController];
}

#pragma mark Getters and setters

- (void)setPlayer:(AVPlayer *)player
{
    _player = player;
    
    AVPlayerItem *playerItem = _player.currentItem;
    
    // Do not check tracks before the player item is ready to play (otherwise AVPlayer will internally wait on semaphores,
    // locking the main thread).
    if (playerItem && playerItem.status == AVPlayerItemStatusReadyToPlay) {
        NSMutableArray<NSString *> *characteristics = [NSMutableArray array];
        NSMutableDictionary<NSString *, AVMediaSelectionGroup *> *selectionGroups = [NSMutableDictionary dictionary];
        
        AVMediaSelectionGroup *legibleGroup = [_player.currentItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
        if (legibleGroup) {
            [characteristics addObject:AVMediaCharacteristicLegible];
            selectionGroups[AVMediaCharacteristicLegible] = legibleGroup;
        }
        
        AVMediaSelectionGroup *audioGroup = [_player.currentItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
        if (audioGroup.options.count > 1) {
            [characteristics addObject:AVMediaCharacteristicAudible];
            selectionGroups[AVMediaCharacteristicAudible] = audioGroup;
        }
        
        self.characteristics = [characteristics copy];
        self.selectionGroups = [selectionGroups copy];
    }
    else {
        self.characteristics = nil;
        self.selectionGroups = nil;
    }
    
    [self.tableView reloadData];
}

- (AVPlayer *)player
{
    return _player;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = SRGMediaPlayerLocalizedString(@"Audio and Subtitles", @"Title of the pop over view to select audio or subtitles");
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass([self class])];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.navigationController.popoverPresentationController) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                               target:self
                                                                                               action:@selector(done:)];
    }
    else {
        self.view.backgroundColor = [UIColor clearColor];
    }
}

#pragma mark Accessibility

- (BOOL)accessibilityPerformEscape
{
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return YES;
    }
    else {
        return NO;
    }
}

#pragma mark UITableViewDataSource protocol

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *characteristic = self.characteristics[section];
    if ([characteristic isEqualToString:AVMediaCharacteristicAudible]) {
        return SRGMediaPlayerLocalizedString(@"Audio", @"Section header title in the alternate tracks popup menu, for audio tracks");
    }
    else if (characteristic == AVMediaCharacteristicLegible) {
        return SRGMediaPlayerLocalizedString(@"Subtitles & CC", @"Section header title in the alternate tracks popup menu, for subtitles & CC tracks");
    }
    else {
        return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *characteristic = self.characteristics[section];
    if ([characteristic isEqualToString:AVMediaCharacteristicLegible]) {
        return SRGMediaPlayerLocalizedString(@"You can adjust the appearance of subtitles in the Accessibility section of the Settings application.", @"Instructions for subtitles customization");
    }
    else {
        return nil;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.characteristics.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *characteristic = self.characteristics[section];
    AVMediaSelectionGroup *group = self.selectionGroups[characteristic];
    return (characteristic == AVMediaCharacteristicLegible) ? group.options.count + 1 : group.options.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([self class]) forIndexPath:indexPath];
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *characteristic = self.characteristics[indexPath.section];
    AVMediaSelectionGroup *group = self.selectionGroups[characteristic];
    
    if (characteristic == AVMediaCharacteristicLegible && indexPath.row == 0) {
        cell.textLabel.text = SRGMediaPlayerLocalizedString(@"No subtitles", @"Option to remove subtitles in alternate tracks popup menu");
        AVMediaSelectionOption *currentOptionInGroup = [self.player.currentItem selectedMediaOptionInMediaSelectionGroup:group];
        cell.accessoryType = currentOptionInGroup ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
    }
    else {
        AVMediaSelectionOption *option = (characteristic == AVMediaCharacteristicLegible) ? group.options[indexPath.row - 1] : group.options[indexPath.row];
        cell.textLabel.text = SRGTitleForMediaOption(option);
        
        AVMediaSelectionOption *currentOptionInGroup = [self.player.currentItem selectedMediaOptionInMediaSelectionGroup:group];
        cell.accessoryType = [currentOptionInGroup isEqual:option] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *characteristic = self.characteristics[indexPath.section];
    AVMediaSelectionGroup *group = self.selectionGroups[characteristic];
    AVMediaSelectionOption *option = nil;
    
    if (characteristic != AVMediaCharacteristicLegible || indexPath.row != 0)  {
        option = (characteristic == AVMediaCharacteristicLegible) ? group.options[indexPath.row - 1] : group.options[indexPath.row];
    }
    
    [self.player.currentItem selectMediaOption:option inMediaSelectionGroup:group];
    
    // Save the subtitle language (system) so that it gets automatically applied again when instantiating a new `AVPlayer` with
    // `appliesMediaSelectionCriteriaAutomatically` (default). For example `SRGMediaPlayerController` or `AVPlayerViewController`
    // within the same app, or even Safari.
    if (characteristic == AVMediaCharacteristicLegible) {
        MACaptionAppearanceAddSelectedLanguage(kMACaptionAppearanceDomainUser, (__bridge CFStringRef _Nonnull)option.locale.localeIdentifier);
    }
    
    if ([self.delegate respondsToSelector:@selector(alternateTracksViewController:didSelectMediaOption:inGroup:)]) {
        [self.delegate alternateTracksViewController:self
                                didSelectMediaOption:option
                                             inGroup:group];
    }
    
    [self.tableView reloadData];
}

#pragma mark Actions

- (void)done:(id)sender
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

@end

static NSString *SRGTitleForMediaOption(AVMediaSelectionOption *option)
{
    // Retrieve title metadata if available (use preferred language settings to present the best one to the user)
    NSArray<AVMetadataItem *> *titleItems = [AVMetadataItem metadataItemsFromArray:option.commonMetadata withKey:AVMetadataCommonKeyTitle keySpace:AVMetadataKeySpaceCommon];
    if (titleItems) {
        titleItems = [AVMetadataItem metadataItemsFromArray:titleItems filteredAndSortedAccordingToPreferredLanguages:NSLocale.preferredLanguages];
        
        NSString *title = titleItems.firstObject.stringValue;
        if (title) {
            return title;
        }
    }
    return option.displayName;
}

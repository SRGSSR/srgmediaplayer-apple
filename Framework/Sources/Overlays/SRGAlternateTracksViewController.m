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
@property (nonatomic) NSDictionary<NSString *, AVMediaSelectionGroup *> *groups;
@property (nonatomic) NSDictionary<NSString *, NSArray<AVMediaSelectionOption *> *> *options;

@property (nonatomic) AVPlayer *player;

@end

@implementation SRGAlternateTracksViewController

@synthesize player = _player;

#pragma mark Class methods

+ (UINavigationController *)alternateTracksNavigationControllerForPlayer:(AVPlayer *)player
{
    SRGAlternateTracksViewController *alternateTracksViewController = [[SRGAlternateTracksViewController alloc] initWithStyle:UITableViewStyleGrouped];
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
        NSMutableDictionary<NSString *, AVMediaSelectionGroup *> *groups = [NSMutableDictionary dictionary];
        NSMutableDictionary<NSString *, NSArray<AVMediaSelectionOption *> *> *options = [NSMutableDictionary dictionary];
        
        AVMediaSelectionGroup *audioGroup = [_player.currentItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
        if (audioGroup.options.count > 1) {
            [characteristics addObject:AVMediaCharacteristicAudible];
            groups[AVMediaCharacteristicAudible] = audioGroup;
            options[AVMediaCharacteristicAudible] = audioGroup.options;
        }
        
        AVMediaSelectionGroup *legibleGroup = [_player.currentItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
        if (legibleGroup) {
            [characteristics addObject:AVMediaCharacteristicLegible];
            groups[AVMediaCharacteristicLegible] = legibleGroup;
            options[AVMediaCharacteristicLegible] = [AVMediaSelectionGroup mediaSelectionOptionsFromArray:legibleGroup.options withoutMediaCharacteristics:@[ AVMediaCharacteristicContainsOnlyForcedSubtitles ]];
        }
        
        self.characteristics = [characteristics copy];
        self.groups = [groups copy];
        self.options = [options copy];
    }
    else {
        self.characteristics = nil;
        self.groups = nil;
        self.options = nil;
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
        return SRGMediaPlayerLocalizedString(@"You can adjust subtitle appearance and automatic selection behavior in the Accessibility section of the Settings application.", @"Instructions for subtitles customization");
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
    NSArray<AVMediaSelectionOption *> *options = self.options[characteristic];
    return (characteristic == AVMediaCharacteristicLegible) ? options.count + 2 : options.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([self class]) forIndexPath:indexPath];
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    MACaptionAppearanceDisplayType displayType = MACaptionAppearanceGetDisplayType(kMACaptionAppearanceDomainUser);
 
    NSString *characteristic = self.characteristics[indexPath.section];
    if (characteristic == AVMediaCharacteristicLegible && indexPath.row == 0) {
        cell.textLabel.text = SRGMediaPlayerLocalizedString(@"Off", @"Option to disable subtitles");
        cell.accessoryType = (displayType == kMACaptionAppearanceDisplayTypeForcedOnly) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else if (characteristic == AVMediaCharacteristicLegible && indexPath.row == 1) {
        cell.textLabel.text = SRGMediaPlayerLocalizedString(@"Auto (Recommended)", @"Recommended option to let subtitles be automatically selected based on user settings");
        cell.accessoryType = (displayType == kMACaptionAppearanceDisplayTypeAutomatic) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else {
        NSArray<AVMediaSelectionOption *> *options = self.options[characteristic];
        AVMediaSelectionOption *option = (characteristic == AVMediaCharacteristicLegible) ? options[indexPath.row - 2] : options[indexPath.row];
        cell.textLabel.text = SRGTitleForMediaOption(option);
        
        AVMediaSelectionGroup *group = self.groups[characteristic];
        AVMediaSelectionOption *currentOptionInGroup = [self.player.currentItem selectedMediaOptionInMediaSelectionGroup:group];
        cell.accessoryType = (displayType == kMACaptionAppearanceDisplayTypeAlwaysOn && [currentOptionInGroup isEqual:option]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *characteristic = self.characteristics[indexPath.section];
    AVMediaSelectionGroup *group = self.groups[characteristic];
    NSArray<AVMediaSelectionOption *> *options = self.options[characteristic];
    
    if (characteristic == AVMediaCharacteristicLegible) {
        if (indexPath.row == 0) {
            [self.player.currentItem selectMediaOption:nil inMediaSelectionGroup:group];
            
            MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeForcedOnly);
        }
        else if (indexPath.row == 1) {
            [self.player.currentItem selectMediaOptionAutomaticallyInMediaSelectionGroup:group];
            
            MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
        }
        else {
            AVMediaSelectionOption *option = options[indexPath.row - 2];
            [self.player.currentItem selectMediaOption:option inMediaSelectionGroup:group];
            
            // Save the subtitle language (system) so that it gets automatically applied again when instantiating a new `AVPlayer` with
            // `appliesMediaSelectionCriteriaAutomatically` (default). For example `SRGMediaPlayerController` or `AVPlayerViewController`
            // within the same app, or even Safari.
            MACaptionAppearanceAddSelectedLanguage(kMACaptionAppearanceDomainUser, (__bridge CFStringRef _Nonnull)option.locale.localeIdentifier);
            MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAlwaysOn);
        }
    }
    else {
        [self.player.currentItem selectMediaOption:options[indexPath.row] inMediaSelectionGroup:group];
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

//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//
#import "SRGAlternateTracksViewController.h"

#import "AVAudioSession+SRGMediaPlayer.h"
#import "NSBundle+SRGMediaPlayer.h"

#import <MediaAccessibility/MediaAccessibility.h>

static NSString *SRGTitleForMediaSelectionOption(AVMediaSelectionOption *option);
static NSString *SRGHintForMediaSelectionOption(AVMediaSelectionOption *option);

@interface SRGAlternateTracksViewController ()

@property (nonatomic) NSArray<NSString *> *characteristics;
@property (nonatomic) NSDictionary<NSString *, AVMediaSelectionGroup *> *groups;
@property (nonatomic) NSDictionary<NSString *, NSArray<AVMediaSelectionOption *> *> *options;

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@property (nonatomic, weak) id periodicTimeObserver;

@end

@implementation SRGAlternateTracksViewController

#pragma mark Class methods

+ (UINavigationController *)alternateTracksNavigationControllerForMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    SRGAlternateTracksViewController *alternateTracksViewController = [[SRGAlternateTracksViewController alloc] initWithStyle:UITableViewStyleGrouped];
    alternateTracksViewController.mediaPlayerController = mediaPlayerController;
    return [[UINavigationController alloc] initWithRootViewController:alternateTracksViewController];
}

#pragma mark Getters and setters

- (void)setMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (_mediaPlayerController) {
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:SRGMediaPlayerAudioTrackDidChangeNotification
                                                    object:_mediaPlayerController];
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:SRGMediaPlayerSubtitleTrackDidChangeNotification
                                                    object:_mediaPlayerController];
    }
    
    _mediaPlayerController = mediaPlayerController;
    
    if (mediaPlayerController) {
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(audioTrackDidChange:)
                                                   name:SRGMediaPlayerAudioTrackDidChangeNotification
                                                 object:mediaPlayerController];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(subtitleTrackDidChange:)
                                                   name:SRGMediaPlayerSubtitleTrackDidChangeNotification
                                                 object:mediaPlayerController];
    }
    
    AVPlayer *player = mediaPlayerController.player;
    AVPlayerItem *playerItem = player.currentItem;
    
    // Do not check tracks before the player item is ready to play (otherwise AVPlayer will internally wait on semaphores,
    // locking the main thread ). Also see `-[AVAsset allMediaSelections]` documentation.
    if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
        NSMutableArray<NSString *> *characteristics = [NSMutableArray array];
        NSMutableDictionary<NSString *, AVMediaSelectionGroup *> *groups = [NSMutableDictionary dictionary];
        NSMutableDictionary<NSString *, NSArray<AVMediaSelectionOption *> *> *options = [NSMutableDictionary dictionary];
        
        AVMediaSelectionGroup *audioGroup = [player.currentItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
        if (audioGroup.options.count > 1) {
            [characteristics addObject:AVMediaCharacteristicAudible];
            groups[AVMediaCharacteristicAudible] = audioGroup;
            options[AVMediaCharacteristicAudible] = audioGroup.options;
        }
        
        AVMediaSelectionGroup *subtitleGroup = [player.currentItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
        if (subtitleGroup) {
            [characteristics addObject:AVMediaCharacteristicLegible];
            groups[AVMediaCharacteristicLegible] = subtitleGroup;
            options[AVMediaCharacteristicLegible] = [AVMediaSelectionGroup mediaSelectionOptionsFromArray:subtitleGroup.options withoutMediaCharacteristics:@[AVMediaCharacteristicContainsOnlyForcedSubtitles]];
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

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = SRGMediaPlayerLocalizedString(@"Audio and Subtitles", @"Title of the pop over view to select audio or subtitles");
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(wirelessRouteDidChange:)
                                               name:SRGMediaPlayerWirelessRouteDidChangeNotification
                                             object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (! self.navigationController.popoverPresentationController) {
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

#pragma mark Cells

- (UITableViewCell *)defaultCellForTableView:(UITableView *)tableView
{
    static NSString * const kCellIdentifier = @"DefaultCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (! cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
    }
    
    cell.textLabel.enabled = YES;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    return cell;
}

- (UITableViewCell *)subtitleCellForTableView:(UITableView *)tableView
{
    static NSString * const kCellIdentifier = @"SubtitleCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (! cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCellIdentifier];
    }
    
    cell.textLabel.enabled = YES;
    cell.detailTextLabel.enabled = YES;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    return cell;
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
    MACaptionAppearanceDisplayType displayType = MACaptionAppearanceGetDisplayType(kMACaptionAppearanceDomainUser);
 
    NSString *characteristic = self.characteristics[indexPath.section];
    if (characteristic == AVMediaCharacteristicLegible) {
        if (indexPath.row == 0) {
            UITableViewCell *cell = [self defaultCellForTableView:tableView];
            cell.textLabel.text = SRGMediaPlayerLocalizedString(@"Off", @"Option to disable subtitles");
            
            if (! AVAudioSession.srg_isAirPlayActive) {
                cell.accessoryType = (displayType == kMACaptionAppearanceDisplayTypeForcedOnly) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            }
            else {
                AVMediaSelectionGroup *group = self.groups[characteristic];
                AVMediaSelectionOption *currentOptionInGroup = [self.mediaPlayerController.player.currentItem selectedMediaOptionInMediaSelectionGroup:group];
                
                cell.accessoryType = (currentOptionInGroup == nil) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            }
            
            return cell;
        }
        else if (indexPath.row == 1) {
            UITableViewCell *cell = [self defaultCellForTableView:tableView];
            cell.textLabel.text = SRGMediaPlayerLocalizedString(@"Auto (Recommended)", @"Recommended option to let subtitles be automatically selected based on user settings");
            
            if (! AVAudioSession.srg_isAirPlayActive) {
                cell.accessoryType = (displayType == kMACaptionAppearanceDisplayTypeAutomatic) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            }
            else {
                cell.textLabel.enabled = NO;
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            
            return cell;
        }
        else {
            UITableViewCell *cell = nil;
            
            AVMediaSelectionOption *option = self.options[characteristic][indexPath.row - 2];
            NSString *title = SRGTitleForMediaSelectionOption(option);
            if (title) {
                cell = [self subtitleCellForTableView:tableView];
                cell.textLabel.text = title;
                cell.detailTextLabel.text = SRGHintForMediaSelectionOption(option);
            }
            else {
                cell = [self defaultCellForTableView:tableView];
                cell.textLabel.text = SRGHintForMediaSelectionOption(option);
            }
            
            AVMediaSelectionGroup *group = self.groups[characteristic];
            AVMediaSelectionOption *currentOptionInGroup = [self.mediaPlayerController.player.currentItem selectedMediaOptionInMediaSelectionGroup:group];
            
            if (! AVAudioSession.srg_isAirPlayActive) {
                cell.accessoryType = (displayType == kMACaptionAppearanceDisplayTypeAlwaysOn && [currentOptionInGroup isEqual:option]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            }
            else {
                cell.accessoryType = [currentOptionInGroup isEqual:option] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            }
            
            return cell;
        }
    }
    else {
        UITableViewCell *cell = nil;
        
        AVMediaSelectionOption *option = self.options[characteristic][indexPath.row];
        NSString *title = SRGTitleForMediaSelectionOption(option);
        if (title) {
            cell = [self subtitleCellForTableView:tableView];
            cell.textLabel.text = title;
            cell.detailTextLabel.text = SRGHintForMediaSelectionOption(option);
        }
        else {
            cell = [self defaultCellForTableView:tableView];
            cell.textLabel.text = SRGHintForMediaSelectionOption(option);
        }
        
        AVMediaSelectionGroup *group = self.groups[characteristic];
        AVMediaSelectionOption *currentOptionInGroup = [self.mediaPlayerController.player.currentItem selectedMediaOptionInMediaSelectionGroup:group];
        cell.accessoryType = [currentOptionInGroup isEqual:option] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    AVPlayer *player = self.mediaPlayerController.player;
    
    NSString *characteristic = self.characteristics[indexPath.section];
    AVMediaSelectionGroup *group = self.groups[characteristic];
    NSArray<AVMediaSelectionOption *> *options = self.options[characteristic];
    
    if (characteristic == AVMediaCharacteristicLegible) {
        if (indexPath.row == 0) {
            [player.currentItem selectMediaOption:nil inMediaSelectionGroup:group];
            
            MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeForcedOnly);
        }
        else if (indexPath.row == 1) {
            [player.currentItem selectMediaOptionAutomaticallyInMediaSelectionGroup:group];
            
            MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
        }
        else {
            AVMediaSelectionOption *option = options[indexPath.row - 2];
            [player.currentItem selectMediaOption:option inMediaSelectionGroup:group];
            
            // Save the subtitle language (system) so that it gets automatically applied again when instantiating a new `AVPlayer` with
            // `appliesMediaSelectionCriteriaAutomatically` (default). For example `SRGMediaPlayerController` or `AVPlayerViewController`
            // within the same app, or even Safari.
            MACaptionAppearanceAddSelectedLanguage(kMACaptionAppearanceDomainUser, (__bridge CFStringRef _Nonnull)[option.locale objectForKey:NSLocaleLanguageCode]);
            MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAlwaysOn);
        }
    }
    else {
        [player.currentItem selectMediaOption:options[indexPath.row] inMediaSelectionGroup:group];
    }
    
    // No track change notification is emitted when the setting (e.g. Automatic or Off) does not lead to another value
    // being selected. We must therefore also fore a refresh to get correct cell state.
    [self.tableView reloadData];
}

#pragma mark Actions

- (void)done:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Notifications

- (void)audioTrackDidChange:(NSNotification *)notification
{
    [self.tableView reloadData];
}

- (void)subtitleTrackDidChange:(NSNotification *)notification
{
    [self.tableView reloadData];
}

- (void)wirelessRouteDidChange:(NSNotification *)notification
{
    [self.tableView reloadData];
}

@end

// Extract the stream title if available. Return `nil` if the option display name suffices.
static NSString *SRGTitleForMediaSelectionOption(AVMediaSelectionOption *option)
{
    // Use option locale to always extract the title from the stream if available, no matter which locale the application is using.
    NSArray<AVMetadataItem *> *titleItems = [AVMetadataItem metadataItemsFromArray:option.commonMetadata withKey:AVMetadataCommonKeyTitle keySpace:AVMetadataKeySpaceCommon];
    NSString *optionLanguage = option.locale.localeIdentifier;
    
    if (titleItems && optionLanguage) {
        NSString *title = [AVMetadataItem metadataItemsFromArray:titleItems filteredAndSortedAccordingToPreferredLanguages:@[optionLanguage]].firstObject.stringValue;
        NSString *displayName = SRGHintForMediaSelectionOption(option);
        if (! [title isEqualToString:displayName]) {
            return title;
        }
    }
    return nil;
}

// Provide a hint for the option, suitable for display in the application locale. A value is always returned.
static NSString *SRGHintForMediaSelectionOption(AVMediaSelectionOption *option)
{
    // If simply using the current locale to localize the display name, the result might vary depending on which
    // languages the application supports. This can lead to different results, some of the redundant (e.g. if the
    // app only supports French). To eliminate such issues, we recreate a simple locale from the current language code.
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:[NSLocale.currentLocale objectForKey:NSLocaleLanguageCode]];
    return [option displayNameWithLocale:locale];
}

//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//
#import "SRGAlternateTracksViewController.h"

#import "MAKVONotificationCenter+SRGMediaPlayer.h"
#import "NSBundle+SRGMediaPlayer.h"
#import "SRGMediaPlayerNavigationController.h"
#import "SRGRouteDetector.h"

#import <libextobjc/libextobjc.h>
#import <MediaAccessibility/MediaAccessibility.h>

static NSString *SRGTitleForMediaSelectionOption(AVMediaSelectionOption *option);
static NSString *SRGHintForMediaSelectionOption(AVMediaSelectionOption *option);
static NSArray<NSString *> *SRGPreferredCaptionLanguageCodes(void);

static void MACaptionAppearanceAddPreferredLanguages(MACaptionAppearanceDomain domain);
static void MACaptionAppearanceAddSelectedLanguages(MACaptionAppearanceDomain domain, NSArray<NSString *> *languageCodes);

@interface SRGAlternateTracksViewController ()

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;
@property (nonatomic) SRGMediaPlayerUserInterfaceStyle userInterfaceStyle;

@property (nonatomic, weak) UITableView *tableView;

@property (nonatomic) NSArray<NSString *> *characteristics;
@property (nonatomic) NSDictionary<NSString *, AVMediaSelectionGroup *> *groups;
@property (nonatomic) NSDictionary<NSString *, NSArray<AVMediaSelectionOption *> *> *options;

@property (nonatomic, weak) id periodicTimeObserver;

@property (nonatomic, readonly, getter=isDark) BOOL dark;

@end

@implementation SRGAlternateTracksViewController

#pragma mark Class methods

+ (UINavigationController *)alternateTracksNavigationControllerForMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
                                                                 withUserInterfaceStyle:(SRGMediaPlayerUserInterfaceStyle)userInterfaceStyle
{
    SRGAlternateTracksViewController *alternateTracksViewController = [[SRGAlternateTracksViewController alloc] initWithMediaPlayerController:mediaPlayerController
                                                                                                                           userInterfaceStyle:userInterfaceStyle];
    return [[SRGMediaPlayerNavigationController alloc] initWithRootViewController:alternateTracksViewController];
}

#pragma mark Object lifecycle

- (instancetype)initWithMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController userInterfaceStyle:(SRGMediaPlayerUserInterfaceStyle)userInterfaceStyle
{
    if (self = [super init]) {
        self.mediaPlayerController = mediaPlayerController;
        self.userInterfaceStyle = userInterfaceStyle;
    }
    return self;
}

#pragma mark Getters and setters

- (NSString *)title
{
    return SRGMediaPlayerLocalizedString(@"Audio and Subtitles", @"Title of the pop over view to select audio or subtitles"); 
}

- (void)setMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (_mediaPlayerController) {
        [_mediaPlayerController removeObserver:self keyPath:@keypath(_mediaPlayerController.player.externalPlaybackActive)];
        
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:SRGMediaPlayerAudioTrackDidChangeNotification
                                                    object:_mediaPlayerController];
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:SRGMediaPlayerSubtitleTrackDidChangeNotification
                                                    object:_mediaPlayerController];
    }
    
    _mediaPlayerController = mediaPlayerController;
    
    if (mediaPlayerController) {
        @weakify(self)
        [mediaPlayerController srg_addMainThreadObserver:self keyPath:@keypath(mediaPlayerController.player.externalPlaybackActive) options:0 block:^(MAKVONotification * _Nonnull notification) {
            @strongify(self)
            [self.tableView reloadData];
        }];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(audioTrackDidChange:)
                                                   name:SRGMediaPlayerAudioTrackDidChangeNotification
                                                 object:mediaPlayerController];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(subtitleTrackDidChange:)
                                                   name:SRGMediaPlayerSubtitleTrackDidChangeNotification
                                                 object:mediaPlayerController];
    }
    
    AVAsset *asset = mediaPlayerController.player.currentItem.asset;
    
    // Never access track information without checking whether it has been loaded first (would lock the main thread)
    if ([asset statusOfValueForKey:@keypath(asset.availableMediaCharacteristicsWithMediaSelectionOptions) error:NULL] == AVKeyValueStatusLoaded) {
        NSMutableArray<NSString *> *characteristics = [NSMutableArray array];
        NSMutableDictionary<NSString *, AVMediaSelectionGroup *> *groups = [NSMutableDictionary dictionary];
        NSMutableDictionary<NSString *, NSArray<AVMediaSelectionOption *> *> *options = [NSMutableDictionary dictionary];
        
        AVMediaSelectionGroup *audioGroup = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
        if (audioGroup.options.count > 1) {
            [characteristics addObject:AVMediaCharacteristicAudible];
            groups[AVMediaCharacteristicAudible] = audioGroup;
            options[AVMediaCharacteristicAudible] = audioGroup.options;
        }
        
        AVMediaSelectionGroup *subtitleGroup = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
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

- (BOOL)isDark
{
    // TODO: Remove SRGMediaPlayerUserInterfaceStyle once SRG Media Player is requiring iOS 12 and above, and
    //       use UIUserInterfaceStyleLight instead.
    if (self.userInterfaceStyle == SRGMediaPlayerUserInterfaceStyleUnspecified) {
        if (@available(iOS 13, *)) {
            return self.traitCollection.userInterfaceStyle != UIUserInterfaceStyleLight;
        }
        else {
            // Use dark as default below iOS 13 (this is the `AVPlayerViewController` default in iOS 11 and 12).
            return YES;
        }
    }
    else {
        return self.userInterfaceStyle == SRGMediaPlayerUserInterfaceStyleDark;
    }
}

- (UIColor *)cellBackgroundColor
{
    return self.dark ? [UIColor colorWithWhite:0.07f alpha:0.75f] : UIColor.whiteColor;
}

- (UIColor *)cellTextColor
{
    if (@available(iOS 13, *)) {
        return [UIColor colorWithWhite:0.5f alpha:1.f];
    }
    else {
        return self.dark ? [UIColor colorWithWhite:0.5f alpha:1.f] : UIColor.blackColor;
    }
}

#pragma mark View lifecycle

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:view.bounds style:UITableViewStyleGrouped];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:tableView];
    self.tableView = tableView;
    
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    // Force properties to avoid overrides with UIAppearance
    UINavigationBar *navigationBarAppearance = [UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[self.class]];
    navigationBarAppearance.barTintColor = nil;
    navigationBarAppearance.tintColor = nil;
    navigationBarAppearance.titleTextAttributes = nil;
    navigationBarAppearance.translucent = YES;
    navigationBarAppearance.shadowImage = nil;
    navigationBarAppearance.backIndicatorImage = nil;
    navigationBarAppearance.backIndicatorTransitionMaskImage = nil;
    [navigationBarAppearance setTitleVerticalPositionAdjustment:0.f forBarMetrics:UIBarMetricsDefault];
    [navigationBarAppearance setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    
    if (@available(iOS 11, *)) {
        navigationBarAppearance.prefersLargeTitles = NO;
        navigationBarAppearance.largeTitleTextAttributes = nil;
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:SRGMediaPlayerLocalizedString(@"OK", @"OK button title")
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(done:)];
    
    [self updateViewAppearance];
}

#pragma mark Status bar

- (UIStatusBarStyle)preferredStatusBarStyle
{
    // TODO: Not called on iOS 13 and above since presented not full screen
    return self.dark ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

#pragma mark Responsiveness

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.popoverPresentationController.sourceRect = self.popoverPresentationController.sourceView.bounds;
    }];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.popoverPresentationController.sourceRect = self.popoverPresentationController.sourceView.bounds;
    }];
}

#pragma mark Traits

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
 
    // TODO: There is a current bug preventing this method from being called in some view controller hierarches like
    //       ours (presentation controller + navigation controller). This should not be the case, as discussed in
    //       https://developer.apple.com/videos/play/wwdc2019/214/ (~27 min). A bug report should be filed, but no
    //       workaround should be made yet.
    //
    //       The result is that the associated view does not correctly update when toggling dark mode while the
    //       tracks popover is on screen.
    if (@available(iOS 13, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateViewAppearance];
        }
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

#pragma mark UI

- (void)updateViewAppearance
{
    BOOL isDark = self.dark;
    
    if (@available(iOS 13, *)) {
        self.navigationController.overrideUserInterfaceStyle = self.dark ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight;
        
        UIBlurEffectStyle blurStyle = isDark ? UIBlurEffectStyleSystemMaterialDark : UIBlurEffectStyleSystemMaterialLight;
        UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:blurStyle];
        self.tableView.backgroundView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        self.tableView.backgroundColor = UIColor.clearColor;
    }
    else {
        self.navigationController.navigationBar.barStyle = isDark ? UIBarStyleBlack : UIBarStyleDefault;
        self.tableView.separatorColor = isDark ? [UIColor colorWithWhite:1.f alpha:0.08f] : UIColor.lightGrayColor;
        self.tableView.backgroundColor = isDark ? UIColor.blackColor : [UIColor colorWithWhite:0.94f alpha:1.f];
    }
    
    [self.tableView reloadData];
}

#pragma mark Cells

- (UITableViewCell *)defaultCellForTableView:(UITableView *)tableView
{
    static NSString * const kCellIdentifier = @"DefaultCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (! cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
    }
    
    cell.backgroundColor = self.cellBackgroundColor;
    
    cell.textLabel.textColor = self.dark ? UIColor.whiteColor : UIColor.blackColor;
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
    
    cell.backgroundColor = self.cellBackgroundColor;
    
    UIColor *textColor = self.dark ? UIColor.whiteColor : UIColor.blackColor;
    cell.textLabel.textColor = textColor;
    cell.textLabel.enabled = YES;
    
    cell.detailTextLabel.textColor = textColor;
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
    AVPlayer *player = self.mediaPlayerController.player;
    AVPlayerItem *playerItem = player.currentItem;
    MACaptionAppearanceDisplayType displayType = MACaptionAppearanceGetDisplayType(kMACaptionAppearanceDomainUser);
    
    NSString *characteristic = self.characteristics[indexPath.section];
    if (characteristic == AVMediaCharacteristicLegible) {
        AVMediaSelectionGroup *group = self.groups[characteristic];
        AVMediaSelectionOption *currentOptionInGroup = [playerItem selectedMediaOptionInMediaSelectionGroup:group];
        
        if (indexPath.row == 0) {
            UITableViewCell *cell = [self defaultCellForTableView:tableView];
            cell.textLabel.text = SRGMediaPlayerLocalizedString(@"Off", @"Option to disable subtitles");
            cell.accessoryType = (displayType == kMACaptionAppearanceDisplayTypeForcedOnly) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            return cell;
        }
        else if (indexPath.row == 1) {
            UITableViewCell *cell = [self defaultCellForTableView:tableView];
            cell.textLabel.text = SRGMediaPlayerLocalizedString(@"Auto (Recommended)", @"Recommended option to let subtitles be automatically selected based on user settings");
            
            if (! player.externalPlaybackActive) {
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
            
            cell.accessoryType = (displayType == kMACaptionAppearanceDisplayTypeAlwaysOn && [currentOptionInGroup isEqual:option]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            
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
        AVMediaSelectionOption *currentOptionInGroup = [playerItem selectedMediaOptionInMediaSelectionGroup:group];
        cell.accessoryType = [currentOptionInGroup isEqual:option] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        
        return cell;
    }
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    AVPlayer *player = self.mediaPlayerController.player;
    AVPlayerItem *playerItem = player.currentItem;
    
    NSString *characteristic = self.characteristics[indexPath.section];
    AVMediaSelectionGroup *group = self.groups[characteristic];
    NSArray<AVMediaSelectionOption *> *options = self.options[characteristic];
    
    if (characteristic == AVMediaCharacteristicLegible) {
        if (indexPath.row == 0) {
            [playerItem selectMediaOption:nil inMediaSelectionGroup:group];
            
            MACaptionAppearanceAddPreferredLanguages(kMACaptionAppearanceDomainUser);
            MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeForcedOnly);
        }
        else if (indexPath.row == 1) {
            [playerItem selectMediaOptionAutomaticallyInMediaSelectionGroup:group];
            
            MACaptionAppearanceAddPreferredLanguages(kMACaptionAppearanceDomainUser);
            MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
        }
        else {
            AVMediaSelectionOption *option = options[indexPath.row - 2];
            [playerItem selectMediaOption:option inMediaSelectionGroup:group];
            
            NSString *languageCode = [option.locale objectForKey:NSLocaleLanguageCode];
            if (languageCode) {
                MACaptionAppearanceAddSelectedLanguages(kMACaptionAppearanceDomainUser, @[languageCode]);
            }
            MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAlwaysOn);
        }
    }
    else {
        [playerItem selectMediaOption:options[indexPath.row] inMediaSelectionGroup:group];
    }
    
    // No track change notification is emitted when the setting (e.g. Automatic or Off) does not lead to another value
    // being selected. We must therefore also fore a refresh to get correct cell state.
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UITableViewHeaderFooterView *)view forSection:(NSInteger)section
{
    view.textLabel.textColor = self.cellTextColor;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UITableViewHeaderFooterView *)view forSection:(NSInteger)section
{
    view.textLabel.textColor = self.cellTextColor;
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

- (void)wirelessRouteActiveDidChange:(NSNotification *)notification
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

// List of preferred languages, from the most to the least preferred one
static NSArray<NSString *> *SRGPreferredCaptionLanguageCodes(void)
{
    NSMutableArray<NSString *> *languageCodes = [NSMutableArray array];
    
    // List of preferred languages from the system settings.
    NSArray<NSString *> *preferredLanguages = NSLocale.preferredLanguages;
    for (NSString *language in preferredLanguages) {
        NSLocale *locale = [NSLocale localeWithLocaleIdentifier:language];
        [languageCodes addObject:[locale objectForKey:NSLocaleLanguageCode]];
    }
    
    // Add current locale language code as last item. The current locale is the one of the app which best matches
    // system settings (even if it does not appear in the preferred language list). Use it as fallback.
    [languageCodes addObject:[NSLocale.currentLocale objectForKey:NSLocaleLanguageCode]];
    
    return [languageCodes copy];
}

// Update the subtitle language selection stack to best match the current language preferences. This helps the "Closed
// Captions + SDH" accessibility feature to find a better match for the user.
//   https://developer.apple.com/documentation/mediaaccessibility/macaptionappearancedisplaytype/kmacaptionappearancedisplaytypealwayson
static void MACaptionAppearanceAddPreferredLanguages(MACaptionAppearanceDomain domain)
{
    MACaptionAppearanceAddSelectedLanguages(kMACaptionAppearanceDomainUser, SRGPreferredCaptionLanguageCodes());
}

// Update the subtitle language selection stack with the provided language list. This list is saved at the system level,
// and is shard by instances of `AVPlayer` with `appliesMediaSelectionCriteriaAutomatically` (default). This includes
// `SRGMediaPlayerController`, but also `AVPlayerController` (within the same app) or Safari.
static void MACaptionAppearanceAddSelectedLanguages(MACaptionAppearanceDomain domain, NSArray<NSString *> *languageCodes)
{
    for (NSString *languageCode in [languageCodes reverseObjectEnumerator]) {
        MACaptionAppearanceAddSelectedLanguage(domain, (__bridge CFStringRef _Nonnull)languageCode);
    }
}

__attribute__((constructor)) static void SRGAlternateTracksViewControllerInit(void)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        MACaptionAppearanceDisplayType displayType = MACaptionAppearanceGetDisplayType(kMACaptionAppearanceDomainUser);
        if  (displayType != kMACaptionAppearanceDisplayTypeAlwaysOn) {
            MACaptionAppearanceAddPreferredLanguages(kMACaptionAppearanceDomainUser);
        }
    });
}

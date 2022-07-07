//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import "SRGPlaybackSettingsViewController.h"

#import "AVMediaSelectionGroup+SRGMediaPlayer.h"
#import "MAKVONotificationCenter+SRGMediaPlayer.h"
#import "NSBundle+SRGMediaPlayer.h"
#import "SRGMediaAccessibility.h"
#import "SRGMediaPlayerController+Private.h"
#import "SRGPlaybackSettingsHeaderView.h"
#import "SRGPlaybackSettingsSegmentCell.h"
#import "SRGRouteDetector.h"

@import libextobjc;

typedef NSString * SRGSettingsSectionType NS_STRING_ENUM;

static SRGSettingsSectionType const SRGSettingsSectionTypePlaybackSpeed = @"playback_speed";
static SRGSettingsSectionType const SRGSettingsSectionTypeAudioTracks = @"audio_tracks";
static SRGSettingsSectionType const SRGSettingsSectionTypeSubtitles = @"subtitles";

static BOOL SRGMediaPlayerIsViewControllerDismissed(UIViewController *viewController);

static NSString *SRGTitleForMediaSelectionOption(AVMediaSelectionOption *option);
static NSString *SRGHintForMediaSelectionOption(AVMediaSelectionOption *option);

static BOOL SRGMediaSelectionOptionHasLanguage(AVMediaSelectionOption *option, NSString *languageCode);
static BOOL SRGMediaSelectionOptionsContainOptionForLanguage(NSArray<AVMediaSelectionOption *> *options, NSString *languageCode);

static NSArray<NSString *> *SRGItemsForPlaybackRates(NSArray<NSNumber *> *playbackRates);

@interface SRGPlaybackSettingsViewController ()

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;
@property (nonatomic) UIUserInterfaceStyle userInterfaceStyle;

@property (nonatomic, weak) UITableView *tableView;

@property (nonatomic) NSArray<SRGSettingsSectionType> *sectionTypes;
@property (nonatomic) NSArray<NSNumber *> *playbackRates;
@property (nonatomic) NSArray<AVMediaSelectionOption *> *audioOptions;
@property (nonatomic) NSArray<AVMediaSelectionOption *> *subtitleOptions;

@property (nonatomic, weak) id periodicTimeObserver;

@property (nonatomic, readonly, getter=isDark) BOOL dark;
@property (nonatomic, readonly) UIPopoverPresentationController *parentPopoverPresentationController;

@end

@implementation SRGPlaybackSettingsViewController

#pragma mark Object lifecycle

- (instancetype)initWithMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController userInterfaceStyle:(UIUserInterfaceStyle)userInterfaceStyle
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
    return SRGMediaPlayerLocalizedString(@"Playback settings", @"Title of the playback settings popover"); 
}

- (void)setMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController
{
    if (_mediaPlayerController) {
        [_mediaPlayerController removeObserver:self keyPath:@keypath(_mediaPlayerController.player.currentItem.asset)];
        [_mediaPlayerController removeObserver:self keyPath:@keypath(_mediaPlayerController.playbackRate)];
        [_mediaPlayerController removeObserver:self keyPath:@keypath(_mediaPlayerController.effectivePlaybackRate)];
        
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
        [mediaPlayerController srg_addMainThreadObserver:self keyPath:@keypath(mediaPlayerController.player.currentItem.asset) options:0 block:^(MAKVONotification * _Nonnull notification) {
            @strongify(self)
            [self reloadData];
        }];
        [mediaPlayerController srg_addMainThreadObserver:self keyPath:@keypath(mediaPlayerController.playbackRate) options:0 block:^(MAKVONotification * _Nonnull notification) {
            @strongify(self)
            [self reloadData];
        }];
        [mediaPlayerController srg_addMainThreadObserver:self keyPath:@keypath(mediaPlayerController.effectivePlaybackRate) options:0 block:^(MAKVONotification * _Nonnull notification) {
            @strongify(self)
            [self reloadData];
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
    
    [self reloadData];
}

- (BOOL)isDark
{
    if (self.userInterfaceStyle == UIUserInterfaceStyleUnspecified) {
        if (@available(iOS 13, *)) {
            return self.traitCollection.userInterfaceStyle != UIUserInterfaceStyleLight;
        }
        else {
            // Use dark as default below iOS 13 (this is the `AVPlayerViewController` default in iOS 11 and 12).
            return YES;
        }
    }
    else {
        return self.userInterfaceStyle == UIUserInterfaceStyleDark;
    }
}

- (UIColor *)cellBackgroundColor
{
    return self.dark ? [UIColor colorWithWhite:0.f alpha:0.2f] : UIColor.whiteColor;
}

- (UIColor *)headerTextColor
{
    return self.dark ? [UIColor colorWithWhite:0.6f alpha:1.f] : [UIColor colorWithWhite:0.4f alpha:1.f];
}

- (UIPopoverPresentationController *)parentPopoverPresentationController
{
    return self.navigationController.popoverPresentationController;
}

#pragma mark View lifecycle

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    [view addSubview:tableView];
    self.tableView = tableView;
    
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [tableView.topAnchor constraintEqualToAnchor:view.topAnchor],
        [tableView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],
        [tableView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [tableView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor]
    ]];
    
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // The style must only be overridden when forced, otherwise no traits change will occur when dark mode is toggled
    // in the system settings.
    if (@available(iOS 13, *)) {
        if (self.userInterfaceStyle != UIUserInterfaceStyleUnspecified) {
            self.navigationController.overrideUserInterfaceStyle = (self.userInterfaceStyle == UIUserInterfaceStyleDark) ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight;
        }
        else {
            self.navigationController.overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
        }
    }
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    Class segmentCellClass = SRGPlaybackSettingsSegmentCell.class;
    [self.tableView registerClass:segmentCellClass forCellReuseIdentifier:NSStringFromClass(segmentCellClass)];
    
    Class headerViewClass = SRGPlaybackSettingsHeaderView.class;
    [self.tableView registerClass:headerViewClass forHeaderFooterViewReuseIdentifier:NSStringFromClass(headerViewClass)];
    
    // Force properties to avoid overrides with UIAppearance
    UINavigationBar *navigationBarAppearance = [UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[self.class]];
    navigationBarAppearance.barTintColor = nil;
    navigationBarAppearance.tintColor = nil;
    navigationBarAppearance.prefersLargeTitles = NO;
    navigationBarAppearance.titleTextAttributes = nil;
    navigationBarAppearance.largeTitleTextAttributes = nil;
    navigationBarAppearance.translucent = YES;
    navigationBarAppearance.shadowImage = nil;
    navigationBarAppearance.backIndicatorImage = nil;
    navigationBarAppearance.backIndicatorTransitionMaskImage = nil;
    [navigationBarAppearance setTitleVerticalPositionAdjustment:0.f forBarMetrics:UIBarMetricsDefault];
    [navigationBarAppearance setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    
    [self updateViewAppearance];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (SRGMediaPlayerIsViewControllerDismissed(self)) {
        [self.delegate playbackSettingsViewControllerWasDismissed:self];
    }
}

#pragma mark Status bar

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.dark ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

#pragma mark Responsiveness

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.parentPopoverPresentationController.sourceRect = self.parentPopoverPresentationController.sourceView.bounds;
    }];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.parentPopoverPresentationController.sourceRect = self.parentPopoverPresentationController.sourceView.bounds;
    }];
}

#pragma mark Traits

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
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

- (void)reloadData
{
    NSMutableArray<SRGSettingsSectionType> *sectionTypes = [NSMutableArray array];
    
    NSArray<NSNumber *> *supportedPlaybackRates = self.mediaPlayerController.supportedPlaybackRates;
    NSAssert(supportedPlaybackRates.count > 1, @"More than one playback speeds must be available");
    [sectionTypes addObject:SRGSettingsSectionTypePlaybackSpeed];
    self.playbackRates = supportedPlaybackRates;
    
    AVAsset *asset = self.mediaPlayerController.player.currentItem.asset;
    if ([asset statusOfValueForKey:@keypath(asset.availableMediaCharacteristicsWithMediaSelectionOptions) error:NULL] == AVKeyValueStatusLoaded) {
        AVMediaSelectionGroup *audioGroup = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
        NSArray<AVMediaSelectionOption *> *audioOptions = audioGroup.options;
        if (audioOptions.count > 1) {
            [sectionTypes addObject:SRGSettingsSectionTypeAudioTracks];
            self.audioOptions = audioOptions;
        }
        else {
            self.audioOptions = nil;
        }
        
        AVMediaSelectionGroup *subtitleGroup = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
        NSArray<AVMediaSelectionOption *> *subtitleOptions = [AVMediaSelectionGroup mediaSelectionOptionsFromArray:subtitleGroup.srgmediaplayer_languageOptions withoutMediaCharacteristics:@[AVMediaCharacteristicContainsOnlyForcedSubtitles]];
        if (subtitleOptions.count != 0) {
            [sectionTypes addObject:SRGSettingsSectionTypeSubtitles];
            self.subtitleOptions = subtitleOptions;
        }
        else {
            self.subtitleOptions = nil;
        }
    }
    else {
        self.audioOptions = nil;
        self.subtitleOptions = nil;
        
        @weakify(self)
        [asset loadValuesAsynchronouslyForKeys:@[ @keypath(asset.availableMediaCharacteristicsWithMediaSelectionOptions) ] completionHandler:^{
            @strongify(self)
            dispatch_async(dispatch_get_main_queue(), ^{
                [self reloadData];
            });
        }];
    }
    
    self.sectionTypes = sectionTypes.copy;
    
    [self.tableView reloadData];
}

- (void)updateViewAppearance
{
    BOOL isDark = self.dark;
    
    if (@available(iOS 13, *)) {
        UIBlurEffectStyle blurStyle = isDark ? UIBlurEffectStyleSystemMaterialDark : UIBlurEffectStyleSystemMaterialLight;
        UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:blurStyle];
        self.tableView.backgroundView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        self.tableView.backgroundColor = [UIColor colorWithWhite:isDark ? 0.f : 1.f alpha:0.8f];
    }
    else {
        self.navigationController.navigationBar.barStyle = isDark ? UIBarStyleBlack : UIBarStyleDefault;
        self.tableView.separatorColor = isDark ? [UIColor colorWithWhite:1.f alpha:0.08f] : UIColor.lightGrayColor;
        
        UIColor *lightBackgroundColor = nil;
#if !TARGET_OS_MACCATALYST
        if (@available(iOS 13, *)) {
#endif
            lightBackgroundColor = UIColor.systemGroupedBackgroundColor;
#if !TARGET_OS_MACCATALYST
        }
        else {
            lightBackgroundColor = UIColor.groupTableViewBackgroundColor;
        }
#endif
        UIColor *backgroundColor = isDark ? [UIColor colorWithWhite:0.17f alpha:1.f] : lightBackgroundColor;
        self.tableView.backgroundColor = backgroundColor;
        self.parentPopoverPresentationController.backgroundColor = backgroundColor;
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

#pragma mark Type-based table view methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSectionWithType:(SRGSettingsSectionType)sectionType
{
    if ([sectionType isEqualToString:SRGSettingsSectionTypePlaybackSpeed]) {
        return SRGMediaPlayerLocalizedString(@"Playback speed", @"Section header title in the settings menu, for setting the playback speed");
    }
    else if ([sectionType isEqualToString:SRGSettingsSectionTypeAudioTracks]) {
        return SRGMediaPlayerLocalizedString(@"Audio", @"Section header title in the settings menu, for audio tracks");
    }
    else if ([sectionType isEqualToString:SRGSettingsSectionTypeSubtitles]) {
        return SRGMediaPlayerLocalizedString(@"Subtitles & CC", @"Section header title in the settings menu, for subtitles & CC tracks");
    }
    else {
        return nil;
    }
}

- (UIImage *)tableView:(UITableView *)tableView imageForHeaderInSectionWithType:(SRGSettingsSectionType)sectionType
{
    if ([sectionType isEqualToString:SRGSettingsSectionTypePlaybackSpeed]) {
        return [UIImage imageNamed:@"playback_speed" inBundle:SWIFTPM_MODULE_BUNDLE compatibleWithTraitCollection:nil];
    }
    else if ([sectionType isEqualToString:SRGSettingsSectionTypeAudioTracks]) {
        return [UIImage imageNamed:@"audio_tracks" inBundle:SWIFTPM_MODULE_BUNDLE compatibleWithTraitCollection:nil];
    }
    else if ([sectionType isEqualToString:SRGSettingsSectionTypeSubtitles]) {
        return [UIImage imageNamed:@"subtitles" inBundle:SWIFTPM_MODULE_BUNDLE compatibleWithTraitCollection:nil];
    }
    else {
        return nil;
    }
}

#pragma mark UITableViewDataSource protocol

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    SRGSettingsSectionType sectionType = self.sectionTypes[section];
    NSString *title = [self tableView:tableView titleForHeaderInSectionWithType:sectionType];
    return (title.length != 0) ? 50.f : 0.f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    SRGPlaybackSettingsHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass(SRGPlaybackSettingsHeaderView.class)];
    
    SRGSettingsSectionType sectionType = self.sectionTypes[section];
    headerView.title = [self tableView:tableView titleForHeaderInSectionWithType:sectionType];
    headerView.image = [self tableView:tableView imageForHeaderInSectionWithType:sectionType];
    return headerView;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    SRGSettingsSectionType sectionType = self.sectionTypes[section];
    if ([sectionType isEqualToString:SRGSettingsSectionTypePlaybackSpeed]) {
        float effectivePlaybackRate = self.mediaPlayerController.effectivePlaybackRate;
        if (self.mediaPlayerController.playbackRate != effectivePlaybackRate) {
            return [NSString stringWithFormat:SRGMediaPlayerLocalizedString(@"The playback speed is restricted to %@×.", @"Information footer about playback speed restrictions"), @(effectivePlaybackRate)];
        }
        else {
            return nil;
        }
    }
    else if ([sectionType isEqualToString:SRGSettingsSectionTypeAudioTracks]) {
        return SRGMediaPlayerLocalizedString(@"You can enable Audio Description automatic selection in the Accessibility settings.", @"Instructions for audio customization");
    }
    else if ([sectionType isEqualToString:SRGSettingsSectionTypeSubtitles]) {
        NSString *autoOptionTitle = SRGMediaPlayerLocalizedString(@"Auto", @"Automatic option title to let subtitles be automatically selected based on user settings");
        NSString *autoOptionInformation = [NSString stringWithFormat:SRGMediaPlayerLocalizedString(@"When '%@' is enabled, and if the selected audio track language differs from the device settings, subtitles or Closed Captions might be displayed automatically.", @"Instructions for subtitles auto option"), autoOptionTitle];
        return [NSString stringWithFormat:@"%@\n\n%@", autoOptionInformation, SRGMediaPlayerLocalizedString(@"You can adjust text appearance and enable Closed Captions and SDH automatic selection in the Accessibility settings.", @"Instructions for subtitles customization")];
    }
    else {
        return nil;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sectionTypes.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    SRGSettingsSectionType sectionType = self.sectionTypes[section];
    if ([sectionType isEqualToString:SRGSettingsSectionTypePlaybackSpeed]) {
        return 1;
    }
    else if ([sectionType isEqualToString:SRGSettingsSectionTypeAudioTracks]) {
        return self.audioOptions.count;
    }
    else if ([sectionType isEqualToString:SRGSettingsSectionTypeSubtitles]) {
        MACaptionAppearanceDisplayType displayType = MACaptionAppearanceGetDisplayType(kMACaptionAppearanceDomainUser);
        if (displayType == kMACaptionAppearanceDisplayTypeAlwaysOn) {
            NSString *lastSelectedLanguage = SRGMediaAccessibilityCaptionAppearanceLastSelectedLanguage(kMACaptionAppearanceDomainUser);
            return SRGMediaSelectionOptionsContainOptionForLanguage(self.subtitleOptions, lastSelectedLanguage) ? self.subtitleOptions.count + 2 : self.subtitleOptions.count + 3;
        }
        else {
            return self.subtitleOptions.count + 2;
        }
    }
    else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MACaptionAppearanceDisplayType displayType = MACaptionAppearanceGetDisplayType(kMACaptionAppearanceDomainUser);
    SRGSettingsSectionType sectionType = self.sectionTypes[indexPath.section];
    
    if ([sectionType isEqualToString:SRGSettingsSectionTypePlaybackSpeed]) {
        SRGPlaybackSettingsSegmentCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(SRGPlaybackSettingsSegmentCell.class)];
        
        @weakify(self)
        [cell setItems:SRGItemsForPlaybackRates(self.playbackRates) reader:^NSInteger{
            @strongify(self)
            NSUInteger index = [self.playbackRates indexOfObject:@(self.mediaPlayerController.playbackRate)];
            NSCAssert(index != NSNotFound, @"Only supported playback rates are displayed");
            return index;
        } writer:^(NSInteger index) {
            @strongify(self)
            // Introduce a slight delay to avoid immediate table view reloads due to the playback rate being changed
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                float rate = self.playbackRates[index].floatValue;
                self.mediaPlayerController.playbackRate = rate;
                
                if ([self.delegate respondsToSelector:@selector(playbackSettingsViewController:didSelectPlaybackRate:)]) {
                    [self.delegate playbackSettingsViewController:self didSelectPlaybackRate:rate];
                }
            });
        }];
        
        cell.backgroundColor = self.cellBackgroundColor;
        return cell;
    }
    else if ([sectionType isEqualToString:SRGSettingsSectionTypeAudioTracks]) {
        UITableViewCell *cell = nil;
        
        AVMediaSelectionOption *option = self.audioOptions[indexPath.row];
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
        
        AVMediaSelectionOption *selectedOption = [self.mediaPlayerController selectedMediaOptionInMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicAudible];
        cell.accessoryType = [selectedOption isEqual:option] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        
        return cell;
    }
    else if ([sectionType isEqualToString:SRGSettingsSectionTypeSubtitles]) {
        BOOL isAutomaticSelectionActive = (displayType == kMACaptionAppearanceDisplayTypeAutomatic) && self.mediaPlayerController.matchesAutomaticSubtitleSelection;
        
        // Off
        if (indexPath.row == 0) {
            UITableViewCell *cell = [self defaultCellForTableView:tableView];
            cell.textLabel.text = SRGMediaPlayerLocalizedString(@"Off", @"Option to disable subtitles");
            
            AVMediaSelectionOption *selectedOption = [self.mediaPlayerController selectedMediaOptionInMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicLegible];
            BOOL hasUnforcedSubtitles = selectedOption && ! [selectedOption hasMediaCharacteristic:AVMediaCharacteristicContainsOnlyForcedSubtitles];
            cell.accessoryType = (! isAutomaticSelectionActive && ! hasUnforcedSubtitles) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            
            return cell;
        }
        // Automatic
        else if (indexPath.row == 1) {
            UITableViewCell *cell = nil;
            
            if (isAutomaticSelectionActive) {
                cell = [self subtitleCellForTableView:tableView];
                
                AVMediaSelectionOption *selectedOption = [self.mediaPlayerController selectedMediaOptionInMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicLegible];
                if (! [selectedOption hasMediaCharacteristic:AVMediaCharacteristicContainsOnlyForcedSubtitles]) {
                    cell.detailTextLabel.text = SRGHintForMediaSelectionOption(selectedOption);
                }
                else {
                    cell.detailTextLabel.text = nil;
                }
            }
            else {
                cell = [self defaultCellForTableView:tableView];
            }
            
            NSString *autoOptionTitle = SRGMediaPlayerLocalizedString(@"Auto", @"Automatic option title to let subtitles be automatically selected based on user settings");
            cell.textLabel.text = [NSString stringWithFormat:SRGMediaPlayerLocalizedString(@"%@ (Recommended)", @"Recommended option (Auto) to let subtitles be automatically selected based on user settings"), autoOptionTitle];
            cell.accessoryType = isAutomaticSelectionActive ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            
            return cell;
        }
        // Additional cell only displayed if the current default language is not found in the available languages
        else if (indexPath.row == self.subtitleOptions.count + 2) {
            UITableViewCell *cell = [self subtitleCellForTableView:tableView];
            
            NSString *lastSelectedLanguage = SRGMediaAccessibilityCaptionAppearanceLastSelectedLanguage(kMACaptionAppearanceDomainUser);
            NSAssert(lastSelectedLanguage != nil, @"Must not be nil by construction (row only available if not nil)");
            
            NSLocale *locale = [NSLocale localeWithLocaleIdentifier:SRGMediaPlayerApplicationLocalization()];
            NSString *languageDisplayName = [locale displayNameForKey:NSLocaleLanguageCode value:lastSelectedLanguage].localizedCapitalizedString ?: SRGMediaPlayerLocalizedString(@"Unknown language", @"Fallback for unknown languages");
            cell.textLabel.text = [NSString stringWithFormat:SRGMediaPlayerLocalizedString(@"%@ (Current default)", @"Entry displayed in the subtitle list to identify the last selected language"), languageDisplayName];
            cell.textLabel.enabled = NO;
            
            cell.detailTextLabel.text = SRGMediaPlayerLocalizedString(@"Language not available for this content", @"Information displayed for unavailable subtitle languages");
            cell.detailTextLabel.enabled = NO;
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.accessoryType = UITableViewCellAccessoryNone;
            
            return cell;
        }
        // Available unforced subtitle languages
        else {
            UITableViewCell *cell = nil;
            
            AVMediaSelectionOption *option = self.subtitleOptions[indexPath.row - 2];
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
            
            AVMediaSelectionOption *selectedOption = [self.mediaPlayerController selectedMediaOptionInMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicLegible];
            cell.accessoryType = (! isAutomaticSelectionActive && [selectedOption isEqual:option]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            
            return cell;
        }
    }
    else {
        return [UITableViewCell new];
    }
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.selectionStyle == UITableViewCellSelectionStyleNone) {
        return;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SRGSettingsSectionType sectionType = self.sectionTypes[indexPath.section];
    if ([sectionType isEqualToString:SRGSettingsSectionTypeAudioTracks]) {
        AVMediaSelectionOption *option = self.audioOptions[indexPath.row];
        [self.mediaPlayerController selectMediaOption:option inMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicAudible];
        
        if ([self.delegate respondsToSelector:@selector(playbackSettingsViewController:didSelectAudioLanguageCode:)]) {
            NSString *languageCode = [option.locale objectForKey:NSLocaleLanguageCode];
            if (! [SRGMediaPlayerApplicationLocalization() isEqualToString:languageCode]) {
                [self.delegate playbackSettingsViewController:self didSelectAudioLanguageCode:languageCode];
            }
            else {
                [self.delegate playbackSettingsViewController:self didSelectAudioLanguageCode:nil];
            }
        }
    }
    else if ([sectionType isEqualToString:SRGSettingsSectionTypeSubtitles]) {
        if (indexPath.row == 0) {
            [self.mediaPlayerController selectMediaOption:nil inMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicLegible];
            SRGMediaAccessibilityCaptionAppearanceAddPreferredLanguages(kMACaptionAppearanceDomainUser);
            MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeForcedOnly);
            
            if ([self.delegate respondsToSelector:@selector(playbackSettingsViewController:didSelectSubtitleLanguageCode:)]) {
                [self.delegate playbackSettingsViewController:self didSelectSubtitleLanguageCode:nil];
            }
        }
        else if (indexPath.row == 1) {
            [self.mediaPlayerController selectMediaOptionAutomaticallyInMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicLegible];
            SRGMediaAccessibilityCaptionAppearanceAddPreferredLanguages(kMACaptionAppearanceDomainUser);
            MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
            
            if ([self.delegate respondsToSelector:@selector(playbackSettingsViewController:didSelectSubtitleLanguageCode:)]) {
                [self.delegate playbackSettingsViewController:self didSelectSubtitleLanguageCode:nil];
            }
        }
        else {
            AVMediaSelectionOption *option = self.subtitleOptions[indexPath.row - 2];
            [self.mediaPlayerController selectMediaOption:option inMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicLegible];
            
            NSString *languageCode = [option.locale objectForKey:NSLocaleLanguageCode];
            if (languageCode) {
                SRGMediaAccessibilityCaptionAppearanceAddSelectedLanguages(kMACaptionAppearanceDomainUser, @[languageCode]);
            }
            MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAlwaysOn);
            
            if ([self.delegate respondsToSelector:@selector(playbackSettingsViewController:didSelectSubtitleLanguageCode:)]) {
                [self.delegate playbackSettingsViewController:self didSelectSubtitleLanguageCode:languageCode];
            }
        }
    }
    
    // No track change notification is emitted when the setting (e.g. Automatic or Off) does not lead to another value
    // being selected. We must therefore also force a refresh to get a correct cell state.
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UITableViewHeaderFooterView *)view forSection:(NSInteger)section
{
    view.tintColor = self.headerTextColor;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UITableViewHeaderFooterView *)view forSection:(NSInteger)section
{
    view.textLabel.textColor = self.headerTextColor;
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

@end

// Check whether the controller is being dismissed, taking parents into account. Only valid for use in `-viewWillDisappear:`
// and `-viewDidDisappear:`.
static BOOL SRGMediaPlayerIsViewControllerDismissed(UIViewController *viewController)
{
    if (viewController.movingFromParentViewController || viewController.beingDismissed) {
        return YES;
    }
    
    UIViewController *parentViewController = viewController.parentViewController;
    while (parentViewController) {
        if (SRGMediaPlayerIsViewControllerDismissed(parentViewController)) {
            return YES;
        }
        parentViewController = parentViewController.parentViewController;
    }
    
    return NO;
}

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
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:SRGMediaPlayerApplicationLocalization()];
    return [option displayNameWithLocale:locale];
}

static BOOL SRGMediaSelectionOptionHasLanguage(AVMediaSelectionOption *option, NSString *languageCode)
{
    NSString *optionLanguageCode = [option.locale objectForKey:NSLocaleLanguageCode];
    return [optionLanguageCode isEqualToString:languageCode];
}

static BOOL SRGMediaSelectionOptionsContainOptionForLanguage(NSArray<AVMediaSelectionOption *> *options, NSString *languageCode)
{
    for (AVMediaSelectionOption *option in options) {
        if (SRGMediaSelectionOptionHasLanguage(option, languageCode)) {
            return YES;
        }
    }
    return NO;
}

static NSArray<NSString *> *SRGItemsForPlaybackRates(NSArray<NSNumber *> *playbackRates)
{
    NSMutableArray<NSString *> *items = [NSMutableArray array];
    for (NSNumber *rate in playbackRates) {
        [items addObject:[NSString stringWithFormat:SRGMediaPlayerLocalizedString(@"%@×", @"Speed factor. Must be short"), rate]];
    }
    return items.copy;
}

__attribute__((constructor)) static void SRGSettingsViewControllerInit(void)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        MACaptionAppearanceDisplayType displayType = MACaptionAppearanceGetDisplayType(kMACaptionAppearanceDomainUser);
        if  (displayType != kMACaptionAppearanceDisplayTypeAlwaysOn) {
            SRGMediaAccessibilityCaptionAppearanceAddPreferredLanguages(kMACaptionAppearanceDomainUser);
        }
    });
}

#endif

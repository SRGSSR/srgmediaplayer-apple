//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import "SRGAlternateTracksViewController.h"

#import "AVMediaSelectionGroup+SRGMediaPlayer.h"
#import "AVPlayerItem+SRGMediaPlayer.h"
#import "MAKVONotificationCenter+SRGMediaPlayer.h"
#import "NSBundle+SRGMediaPlayer.h"
#import "SRGAlternateTracksSegmentCell.h"
#import "SRGMediaAccessibility.h"
#import "SRGMediaPlayerController+Private.h"
#import "SRGRouteDetector.h"

@import libextobjc;

typedef NSString * SRGAlternateTracksSectionType NS_STRING_ENUM;

static SRGAlternateTracksSectionType const SRGAlternateTracksSectionTypePlaybackSpeed = @"playback_speed";
static SRGAlternateTracksSectionType const SRGAlternateTracksSectionTypeAudioTracks = @"audio_tracks";
static SRGAlternateTracksSectionType const SRGAlternateTracksSectionTypeSubtitles = @"subtitles";

static BOOL SRGMediaPlayerIsViewControllerDismissed(UIViewController *viewController);

static NSString *SRGTitleForMediaSelectionOption(AVMediaSelectionOption *option);
static NSString *SRGHintForMediaSelectionOption(AVMediaSelectionOption *option);

static BOOL SRGMediaSelectionOptionHasLanguage(AVMediaSelectionOption *option, NSString *languageCode);
static BOOL SRGMediaSelectionOptionsContainOptionForLanguage(NSArray<AVMediaSelectionOption *> *options, NSString *languageCode);

static NSArray<NSString *> *SRGItemsForPlaybackRates(NSArray<NSNumber *> *playbackRates);

@interface SRGAlternateTracksViewController ()

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;
@property (nonatomic) SRGMediaPlayerUserInterfaceStyle userInterfaceStyle;

@property (nonatomic, weak) UITableView *tableView;

@property (nonatomic) NSArray<SRGAlternateTracksSectionType> *sectionTypes;
@property (nonatomic) NSArray<NSNumber *> *playbackRates;
@property (nonatomic) NSArray<AVMediaSelectionOption *> *audioOptions;
@property (nonatomic) NSArray<AVMediaSelectionOption *> *subtitleOptions;

@property (nonatomic, weak) id periodicTimeObserver;

@property (nonatomic, readonly, getter=isDark) BOOL dark;
@property (nonatomic, readonly) UIPopoverPresentationController *parentPopoverPresentationController;

@end

@implementation SRGAlternateTracksViewController

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
        [_mediaPlayerController removeObserver:self keyPath:@keypath(_mediaPlayerController.player.currentItem.asset)];
        [_mediaPlayerController removeObserver:self keyPath:@keypath(_mediaPlayerController.playbackRate)];
        [_mediaPlayerController removeObserver:self keyPath:@keypath(_mediaPlayerController.alternativePlaybackRates)];
        
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
        [mediaPlayerController srg_addMainThreadObserver:self keyPath:@keypath(mediaPlayerController.alternativePlaybackRates) options:0 block:^(MAKVONotification * _Nonnull notification) {
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
    // TODO: Remove SRGMediaPlayerUserInterfaceStyle once SRG Media Player is requiring iOS 12 and above, and
    //       use UIUserInterfaceStyle instead.
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

- (UIColor *)headerTextColor
{
    return [UIColor colorWithWhite:0.5f alpha:1.f];
}

- (UIPopoverPresentationController *)parentPopoverPresentationController
{
    return self.navigationController.popoverPresentationController;
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
    
    // The style must only be overridden when forced, otherwise no traits change will occur when dark mode is toggled
    // in the system settings.
    if (@available(iOS 13, *)) {
        if (self.userInterfaceStyle != SRGMediaPlayerUserInterfaceStyleUnspecified) {
            self.navigationController.overrideUserInterfaceStyle = (self.userInterfaceStyle == SRGMediaPlayerUserInterfaceStyleDark) ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight;
        }
        else {
            self.navigationController.overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
        }
    }
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    Class segmentCellClass = SRGAlternateTracksSegmentCell.class;
    [self.tableView registerClass:segmentCellClass forCellReuseIdentifier:NSStringFromClass(segmentCellClass)];
    
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
    
    [self updateViewAppearance];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (SRGMediaPlayerIsViewControllerDismissed(self)) {
        [self.delegate alternateTracksViewControllerWasDismissed:self];
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
    AVAsset *asset = self.mediaPlayerController.player.currentItem.asset;
    if ([asset statusOfValueForKey:@keypath(asset.availableMediaCharacteristicsWithMediaSelectionOptions) error:NULL] == AVKeyValueStatusLoaded) {
        NSMutableArray<SRGAlternateTracksSectionType> *sectionTypes = [NSMutableArray array];
        
        // Displayed only if additional standard playback speeds have been set
        NSSet<NSNumber *> *alternativePlaybackRates = self.mediaPlayerController.alternativePlaybackRates;
        if (alternativePlaybackRates.count != 0) {
            [sectionTypes addObject:SRGAlternateTracksSectionTypePlaybackSpeed];
            
            NSSet<NSNumber *> *supportedPlaybackRates = [alternativePlaybackRates setByAddingObject:@1];
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
            self.playbackRates = [supportedPlaybackRates sortedArrayUsingDescriptors:@[sortDescriptor]];
        }
        
        // Displayed only if several audio options are available
        AVMediaSelectionGroup *audioGroup = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
        NSArray<AVMediaSelectionOption *> *audioOptions = audioGroup.options;
        if (audioOptions.count > 1) {
            [sectionTypes addObject:SRGAlternateTracksSectionTypeAudioTracks];
            self.audioOptions = audioOptions;
        }
        else {
            self.audioOptions = nil;
        }
        
        // Displayed if a subtitle group is available (even if empty; None and Automatic are always valid additional values)
        AVMediaSelectionGroup *subtitleGroup = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
        if (subtitleGroup) {
            [sectionTypes addObject:SRGAlternateTracksSectionTypeSubtitles];
            self.subtitleOptions = [AVMediaSelectionGroup mediaSelectionOptionsFromArray:subtitleGroup.srgmediaplayer_languageOptions withoutMediaCharacteristics:@[AVMediaCharacteristicContainsOnlyForcedSubtitles]];
        }
        else {
            self.subtitleOptions = nil;
        }
        
        self.sectionTypes = sectionTypes.copy;
    }
    else {
        self.sectionTypes = nil;
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
    
    [self.tableView reloadData];
}

- (void)updateViewAppearance
{
    BOOL isDark = self.dark;
    
    if (@available(iOS 13, *)) {
        UIBlurEffectStyle blurStyle = isDark ? UIBlurEffectStyleSystemMaterialDark : UIBlurEffectStyleSystemMaterialLight;
        UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:blurStyle];
        self.tableView.backgroundView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        self.tableView.backgroundColor = UIColor.clearColor;
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

#pragma mark UITableViewDataSource protocol

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    SRGAlternateTracksSectionType sectionType = self.sectionTypes[section];
    if ([sectionType isEqualToString:SRGAlternateTracksSectionTypePlaybackSpeed]) {
        return SRGMediaPlayerLocalizedString(@"Playback speed", @"Section header title in the alternate tracks popup menu, for setting the playback speed");
    }
    else if ([sectionType isEqualToString:SRGAlternateTracksSectionTypeAudioTracks]) {
        return SRGMediaPlayerLocalizedString(@"Audio", @"Section header title in the alternate tracks popup menu, for audio tracks");
    }
    else if ([sectionType isEqualToString:SRGAlternateTracksSectionTypeSubtitles]) {
        return SRGMediaPlayerLocalizedString(@"Subtitles & CC", @"Section header title in the alternate tracks popup menu, for subtitles & CC tracks");
    }
    else {
        return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    SRGAlternateTracksSectionType sectionType = self.sectionTypes[section];
    if ([sectionType isEqualToString:SRGAlternateTracksSectionTypeAudioTracks]) {
        return SRGMediaPlayerLocalizedString(@"You can enable Audio Description automatic selection in the Accessibility settings.", @"Instructions for audio customization");
    }
    else if ([sectionType isEqualToString:SRGAlternateTracksSectionTypeSubtitles]) {
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
    SRGAlternateTracksSectionType sectionType = self.sectionTypes[section];
    if ([sectionType isEqualToString:SRGAlternateTracksSectionTypePlaybackSpeed]) {
        return 1;
    }
    else if ([sectionType isEqualToString:SRGAlternateTracksSectionTypeAudioTracks]) {
        return self.audioOptions.count;
    }
    else if ([sectionType isEqualToString:SRGAlternateTracksSectionTypeSubtitles]) {
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
    SRGAlternateTracksSectionType sectionType = self.sectionTypes[indexPath.section];
    
    if ([sectionType isEqualToString:SRGAlternateTracksSectionTypePlaybackSpeed]) {
        SRGAlternateTracksSegmentCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(SRGAlternateTracksSegmentCell.class)];
        
        @weakify(self)
        [cell setItems:SRGItemsForPlaybackRates(self.playbackRates) reader:^NSInteger{
            @strongify(self)
            NSUInteger index = [self.playbackRates indexOfObject:@(self.mediaPlayerController.playbackRate)];
            NSCAssert(index != NSNotFound, @"Only supported playback rates are displayed");
            return index;
        } writer:^(NSInteger index) {
            @strongify(self)
            NSNumber *rate = self.playbackRates[index];
            self.mediaPlayerController.playbackRate = rate.floatValue;
        }];
        return cell;
    }
    else if ([sectionType isEqualToString:SRGAlternateTracksSectionTypeAudioTracks]) {
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
    else if ([sectionType isEqualToString:SRGAlternateTracksSectionTypeSubtitles]) {
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
                cell.detailTextLabel.text = SRGHintForMediaSelectionOption(selectedOption) ?: SRGMediaPlayerLocalizedString(@"None", @"Label displayed when no subtitles have been selected in automatic mode");
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
        return nil;
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
    
    SRGAlternateTracksSectionType sectionType = self.sectionTypes[indexPath.section];
    if ([sectionType isEqualToString:SRGAlternateTracksSectionTypePlaybackSpeed]) {
        
    }
    else if ([sectionType isEqualToString:SRGAlternateTracksSectionTypeAudioTracks]) {
        [self.mediaPlayerController selectMediaOption:self.audioOptions[indexPath.row] inMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicAudible];
    }
    else if ([sectionType isEqualToString:SRGAlternateTracksSectionTypeSubtitles]) {
        if (indexPath.row == 0) {
            [self.mediaPlayerController selectMediaOption:nil inMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicLegible];
            SRGMediaAccessibilityCaptionAppearanceAddPreferredLanguages(kMACaptionAppearanceDomainUser);
            MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeForcedOnly);
        }
        else if (indexPath.row == 1) {
            [self.mediaPlayerController selectMediaOptionAutomaticallyInMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicLegible];
            SRGMediaAccessibilityCaptionAppearanceAddPreferredLanguages(kMACaptionAppearanceDomainUser);
            MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
        }
        else {
            AVMediaSelectionOption *option = self.subtitleOptions[indexPath.row - 2];
            [self.mediaPlayerController selectMediaOption:option inMediaSelectionGroupWithCharacteristic:AVMediaCharacteristicLegible];
            
            NSString *languageCode = [option.locale objectForKey:NSLocaleLanguageCode];
            if (languageCode) {
                SRGMediaAccessibilityCaptionAppearanceAddSelectedLanguages(kMACaptionAppearanceDomainUser, @[languageCode]);
            }
            MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAlwaysOn);
        }
    }
    
    // No track change notification is emitted when the setting (e.g. Automatic or Off) does not lead to another value
    // being selected. We must therefore also force a refresh to get a correct cell state.
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UITableViewHeaderFooterView *)view forSection:(NSInteger)section
{
    view.textLabel.textColor = self.headerTextColor;
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
        [items addObject:[NSString stringWithFormat:@"%@×", rate]];
    }
    return items.copy;
}

__attribute__((constructor)) static void SRGAlternateTracksViewControllerInit(void)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        MACaptionAppearanceDisplayType displayType = MACaptionAppearanceGetDisplayType(kMACaptionAppearanceDomainUser);
        if  (displayType != kMACaptionAppearanceDisplayTypeAlwaysOn) {
            SRGMediaAccessibilityCaptionAppearanceAddPreferredLanguages(kMACaptionAppearanceDomainUser);
        }
    });
}

#endif

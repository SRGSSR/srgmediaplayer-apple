//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//
#import "SRGAlternateTracksViewController.h"

#import "NSBundle+SRGMediaPlayer.h"

BOOL SRGIsCharacteristicLegible(NSString *characteristic)
{
    return [characteristic isEqual:AVMediaCharacteristicLegible];
}

@interface SRGAlternateTracksViewController ()

@property (nonatomic) NSArray<NSString *> *characteristics;
@property (nonatomic) NSDictionary<NSString *, AVMediaSelectionGroup *> *tracksGroupByCharacteristics;

@property (nonatomic) AVPlayer *player;

@end

@implementation SRGAlternateTracksViewController

@synthesize delegate = _delegate;
@synthesize player = _player;

+ (UIPopoverController *)alternateTracksViewControllerInPopoverForPlayer:(AVPlayer *)player delegate:(nullable id<SRGAlternateTracksViewControllerDelegate>)delegate
{
    UINavigationController *navigationController = [SRGAlternateTracksViewController alternateTracksViewControllerInNavigationControllerForPlayer:player
                                                                                                                                         delegate:delegate];
    UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
    return popoverController;
}

+ (UINavigationController *)alternateTracksViewControllerInNavigationControllerForPlayer:(AVPlayer *)player delegate:(nullable id<SRGAlternateTracksViewControllerDelegate>)delegate
{
    SRGAlternateTracksViewController *alternateTracksViewController = [[SRGAlternateTracksViewController alloc] initWithStyle:UITableViewStyleGrouped];
    alternateTracksViewController.delegate = delegate;
    alternateTracksViewController.player = player;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:alternateTracksViewController];
    return navigationController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = SRGMediaPlayerLocalizedString(@"Audio and Subtitles", nil);
    
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

- (void)setPlayer:(AVPlayer *)player {
    _player = player;
    
    AVMediaSelectionGroup *legibleGroup = [_player.currentItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
    AVMediaSelectionGroup *audioGroup = [_player.currentItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
    if (audioGroup.options.count < 2) {
        audioGroup = nil;
    }
    
    self.characteristics = @[];
    NSMutableDictionary *tracksGroupByCharacteristics = @{}.mutableCopy;
    
    tracksGroupByCharacteristics[AVMediaCharacteristicLegible] = legibleGroup;
    tracksGroupByCharacteristics[AVMediaCharacteristicAudible] = audioGroup;
    
    if (legibleGroup) {
        self.characteristics = [self.characteristics arrayByAddingObject:AVMediaCharacteristicLegible];
    }
    if (audioGroup) {
        self.characteristics = [self.characteristics arrayByAddingObject:AVMediaCharacteristicAudible];
    }
    
    self.tracksGroupByCharacteristics = tracksGroupByCharacteristics.copy;
    [self.tableView reloadData];
}

- (AVPlayer *)player {
    return _player;
}

#pragma mark UITableViewDataSource protocol

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *characteristic = self.characteristics[section];
    if ([characteristic isEqualToString:AVMediaCharacteristicAudible]) {
        return SRGMediaPlayerLocalizedString(@"Audio", nil);
    }
    else if (SRGIsCharacteristicLegible(characteristic)) {
        return SRGMediaPlayerLocalizedString(@"Subtitles & CC", nil);
    }
    else {
       return @"";
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.characteristics.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *characteristic = self.characteristics[section];
    AVMediaSelectionGroup *group = self.tracksGroupByCharacteristics[characteristic];
    return SRGIsCharacteristicLegible(characteristic) ? group.options.count + 1 : group.options.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([self class]) forIndexPath:indexPath];
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *characteristic = self.characteristics[indexPath.section];
    AVMediaSelectionGroup *group = self.tracksGroupByCharacteristics[characteristic];
    // OFF option for subtitles needs a customisation
    if (SRGIsCharacteristicLegible(characteristic) && indexPath.row == 0) {
        cell.textLabel.text = SRGMediaPlayerLocalizedString(@"No subtitles", @"Option to remove subtitles");
        AVMediaSelectionOption *currentOptionInGroup = [self.player.currentItem selectedMediaOptionInMediaSelectionGroup:group];
        cell.accessoryType = (!currentOptionInGroup) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else {
        AVMediaSelectionOption *option = SRGIsCharacteristicLegible(characteristic) ? group.options[indexPath.row -1] : group.options[indexPath.row];
        cell.textLabel.text = option.displayName;
        
        AVMediaSelectionOption *currentOptionInGroup = [self.player.currentItem selectedMediaOptionInMediaSelectionGroup:group];
        cell.accessoryType = [currentOptionInGroup isEqual:option] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *characteristic = self.characteristics[indexPath.section];
    AVMediaSelectionGroup *group = self.tracksGroupByCharacteristics[characteristic];
    AVMediaSelectionOption *option = nil;
    // OFF option for subtitles needs a customisation
    if (!(SRGIsCharacteristicLegible(characteristic) && indexPath.row == 0)) {
        option = SRGIsCharacteristicLegible(characteristic) ? group.options[indexPath.row -1] : group.options[indexPath.row];
    }
    
    [self.player.currentItem selectMediaOption:option inMediaSelectionGroup:group];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(alternateTracksViewController:selectedMediaOption:inGroup:)]) {
        [self.delegate alternateTracksViewController:self
                                 selectedMediaOption:option
                                             inGroup:group];
    }
    
    [self.tableView reloadData];
}

#pragma mark - Actions
- (void)done:(id)sender {
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

@end

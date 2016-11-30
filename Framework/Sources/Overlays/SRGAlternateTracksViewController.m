//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//
#import "SRGAlternateTracksViewController.h"

#import "NSBundle+SRGMediaPlayer.h"

@interface SRGAlternateTracksViewController ()

@property (nonatomic) NSArray *characteristics;
@property (nonatomic) NSDictionary *tracksGroupByCharacteristics;

@property (nonatomic) AVPlayer *player;

@end

@implementation SRGAlternateTracksViewController

@synthesize delegate = _delegate;
@synthesize player = _player;

+ (UIPopoverController *)alternateTracksViewControllerInPopoverWithDelegate:(id<SRGAlternateTracksViewControllerDelegate>)delegate player:(AVPlayer *)player
{
    SRGAlternateTracksViewController *trackSelector = [[SRGAlternateTracksViewController alloc] init];
    trackSelector.delegate = delegate;
    trackSelector.player = player;
    UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:trackSelector];
    return popover;
}

+ (UINavigationController *)alternateTracksViewControllerInNavigationControllerWithDelegate:(id<SRGAlternateTracksViewControllerDelegate>)delegate player:(AVPlayer *)player
{
    SRGAlternateTracksViewController *trackSelector = [[SRGAlternateTracksViewController alloc] init];
    trackSelector.delegate = delegate;
    trackSelector.player = player;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:trackSelector];
    return nav;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(done:)];
}

- (void)setPlayer:(AVPlayer *)player {
    _player = player;
    
    AVMediaSelectionGroup *legibleGroup = [_player.currentItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
    AVMediaSelectionGroup *audioGroup = [_player.currentItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
    if (audioGroup.options.count < 2) {
        audioGroup = nil;
    }
    AVMediaSelectionGroup *visualGroup = [_player.currentItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicVisual];
    
    self.characteristics = @[];
    NSMutableDictionary *tracksGroupByCharacteristics = @{}.mutableCopy;
    
    tracksGroupByCharacteristics[AVMediaCharacteristicLegible] = legibleGroup;
    tracksGroupByCharacteristics[AVMediaCharacteristicAudible] = audioGroup;
    tracksGroupByCharacteristics[AVMediaCharacteristicVisual] = visualGroup;
    
    if (legibleGroup) {
        self.characteristics = [self.characteristics arrayByAddingObject:AVMediaCharacteristicLegible];
    }
    if (audioGroup) {
        self.characteristics = [self.characteristics arrayByAddingObject:AVMediaCharacteristicAudible];
    }
    if (visualGroup) {
        self.characteristics = [self.characteristics arrayByAddingObject:AVMediaCharacteristicVisual];
    }
    
    self.tracksGroupByCharacteristics = tracksGroupByCharacteristics.copy;
    [self.tableView reloadData];
}

- (AVPlayer *)player {
    return _player;
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *characteristic = self.characteristics[section];
    if ([characteristic isEqualToString:AVMediaCharacteristicAudible]) {
        return SRGMediaPlayerLocalizedString(@"Audio Languages", nil);
    }
    else if ([characteristic isEqualToString:AVMediaCharacteristicLegible]) {
        return SRGMediaPlayerLocalizedString(@"Subtitles", nil);
    }
    else if ([characteristic isEqualToString:AVMediaCharacteristicVisual]) {
        return SRGMediaPlayerLocalizedString(@"Video", nil);
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
    return [characteristic isEqual:AVMediaCharacteristicLegible] ? group.options.count + 1 : group.options.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AlternateTracksViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    NSString *characteristic = self.characteristics[indexPath.section];
    AVMediaSelectionGroup *group = self.tracksGroupByCharacteristics[characteristic];
    // OFF option for subtitles needs a customisation
    if ([characteristic isEqual:AVMediaCharacteristicLegible] && indexPath.row == 0) {
        cell.textLabel.text = SRGMediaPlayerLocalizedString(@"OFF", @"No subtitle option in alternate tracks list");
        AVMediaSelectionOption *currentOptionInGroup = [self.player.currentItem selectedMediaOptionInMediaSelectionGroup:group];
        cell.accessoryType = (!currentOptionInGroup) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else {
        AVMediaSelectionOption *option = [characteristic isEqual:AVMediaCharacteristicLegible] ? group.options[indexPath.row -1] : group.options[indexPath.row];
        cell.textLabel.text = option.displayName;
        
        AVMediaSelectionOption *currentOptionInGroup = [self.player.currentItem selectedMediaOptionInMediaSelectionGroup:group];
        cell.accessoryType = [currentOptionInGroup isEqual:option] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *characteristic = self.characteristics[indexPath.section];
    AVMediaSelectionGroup *group = self.tracksGroupByCharacteristics[characteristic];
    AVMediaSelectionOption *option = nil;
    // OFF option for subtitles needs a customisation
    if ([characteristic isEqual:AVMediaCharacteristicLegible] && indexPath.row != 0){
        option = [characteristic isEqual:AVMediaCharacteristicLegible] ? group.options[indexPath.row -1] : group.options[indexPath.row];
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

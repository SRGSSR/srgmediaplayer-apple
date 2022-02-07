//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAlternateTracksSegmentCell.h"

@interface SRGAlternateTracksSegmentCell ()

@property (nonatomic) NSArray<NSString *> *items;

@property (nonatomic, copy) NSInteger (^reader)(void);
@property (nonatomic, copy) void (^writer)(NSInteger index);

@property (nonatomic, weak) UISegmentedControl *segmentedControl;

@end

@implementation SRGAlternateTracksSegmentCell

#pragma mark Object lifecycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithFrame:self.contentView.bounds];
        segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
        [segmentedControl addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
        [self.contentView addSubview:segmentedControl];
        self.segmentedControl = segmentedControl;
        
        [NSLayoutConstraint activateConstraints:@[
            [segmentedControl.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16.f],
            [segmentedControl.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16.f],
            [segmentedControl.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12.f],
            [segmentedControl.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-12.f]
        ]];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.clearColor;
    }
    return self;
}

#pragma mark Getters and setters

- (void)setItems:(NSArray<NSString *> *)items reader:(NSInteger (^)(void))reader writer:(void (^)(NSInteger))writer
{
    self.items = items;
    
    self.reader = reader;
    self.writer = writer;
    
    [self reloadData];
}

#pragma mark UI

- (void)reloadData
{
    [self.segmentedControl removeAllSegments];
    [self.items enumerateObjectsUsingBlock:^(NSString * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.segmentedControl insertSegmentWithTitle:item atIndex:idx animated:NO];
    }];
    self.segmentedControl.selectedSegmentIndex = self.reader ? self.reader() : UISegmentedControlNoSegment;
}

#pragma mark Actions

- (void)valueChanged:(id)sender
{
    if (self.writer) {
        self.writer(self.segmentedControl.selectedSegmentIndex);
    }
}

@end

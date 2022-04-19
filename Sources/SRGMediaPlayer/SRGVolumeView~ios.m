//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import "NSBundle+SRGMediaPlayer.h"
#import "SRGVolumeView.h"

@import MediaPlayer;

@interface SRGVolumeView ()

@property (nonatomic, weak) MPVolumeView *volumeView;

@end

@implementation SRGVolumeView

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:self.bounds];
    volumeView.showsRouteButton = NO;
    [self addSubview:volumeView];
    self.volumeView = volumeView;
    
    volumeView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [volumeView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [volumeView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [volumeView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [volumeView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor]
    ]];
}

- (CGSize)intrinsicContentSize
{
    return self.volumeView.intrinsicContentSize;
}

#pragma mark Getters and setters

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    [self.volumeView setHidden:hidden];
}

#pragma mark Interface Builder integration

- (void)prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];
    
    UILabel *placeholderLabel = [[UILabel alloc] initWithFrame:self.bounds];
    placeholderLabel.textColor = UIColor.whiteColor;
    placeholderLabel.textAlignment = NSTextAlignmentCenter;
    placeholderLabel.text = SRGMediaPlayerNonLocalizedString(@"Volume view (only visible on a device)");
    [self addSubview:placeholderLabel];
    
    placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [placeholderLabel.topAnchor constraintEqualToAnchor:self.topAnchor],
        [placeholderLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [placeholderLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [placeholderLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor]
    ]];
}

@end

#endif

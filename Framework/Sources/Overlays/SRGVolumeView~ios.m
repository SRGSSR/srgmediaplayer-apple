//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGVolumeView.h"

#import "NSBundle+SRGMediaPlayer.h"

#import <MediaPlayer/MediaPlayer.h>

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
    volumeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:volumeView];
    self.volumeView = volumeView;
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
    placeholderLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    placeholderLabel.text = SRGMediaPlayerNonLocalizedString(@"Volume view (only visible on a device)");
    [self addSubview:placeholderLabel];
}

@end

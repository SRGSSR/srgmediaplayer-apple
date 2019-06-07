//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGVolumeView.h"

#import "NSBundle+SRGMediaPlayer.h"

#import <MediaPlayer/MediaPlayer.h>

@interface SRGVolumeView ()

@end

@implementation SRGVolumeView

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
}


#pragma mark Getters and setters

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    
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

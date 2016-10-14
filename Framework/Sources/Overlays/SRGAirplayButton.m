//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAirplayButton.h"

#import <libextobjc/libextobjc.h>
#import <MediaPlayer/MediaPlayer.h>

static void commonInit(SRGAirplayButton *self);

@interface SRGAirplayButton ()

@property (nonatomic, weak) MPVolumeView *volumeView;

@end

@implementation SRGAirplayButton

#pragma mark Object lifecycle

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        commonInit(self);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        commonInit(self);
    }
    return self;
}

#pragma mark Overrides

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        self.hidden = ! self.volumeView.areWirelessRoutesAvailable;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(srg_airplayButton_wirelessRoutesAvailableDidChange:)
                                                     name:MPVolumeViewWirelessRoutesAvailableDidChangeNotification
                                                   object:self.volumeView];
    }
    else {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:MPVolumeViewWirelessRoutesAvailableDidChangeNotification
                                                      object:self.volumeView];
    }
}

#pragma mark Notifications

- (void)srg_airplayButton_wirelessRoutesAvailableDidChange:(NSNotification *)notification
{
    self.hidden = ! self.volumeView.areWirelessRoutesAvailable;
}

#pragma mark Interface Builder integration

- (void)prepareForInterfaceBuilder
{
    self.backgroundColor = [UIColor greenColor];
}

@end

static void commonInit(SRGAirplayButton *self)
{
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:self.bounds];
    volumeView.showsVolumeSlider = NO;
    volumeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:volumeView];
    self.volumeView = volumeView;
}

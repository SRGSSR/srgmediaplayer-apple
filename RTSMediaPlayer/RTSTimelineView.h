//
//  Created by Samuel Défago on 28.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <RTSMediaPlayer/RTSTimelineEvent.h>
#import <UIKit/UIKit.h>

@class RTSMediaPlayerController;
@protocol RTSTimelineViewDataSource;

@interface RTSTimelineView : UIView <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic) NSArray *events;

@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;

- (void) registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier;
- (void) registerNib:(UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier;

- (id) dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forEvent:(RTSTimelineEvent *)event;

@property (nonatomic, weak) IBOutlet id<RTSTimelineViewDataSource> dataSource;

@end

@protocol RTSTimelineViewDataSource <NSObject>

// TODO: Add methods for item width and spacing

- (UICollectionViewCell *) timelineView:(RTSTimelineView *)timelineView cellForEvent:(RTSTimelineEvent *)event;

@end

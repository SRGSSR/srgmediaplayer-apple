//
//  Created by Samuel Défago on 28.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <RTSMediaPlayer/RTSTimelineEvent.h>
#import <UIKit/UIKit.h>

@class RTSMediaPlayerController;
@protocol RTSTimelineViewDataSource;
@protocol RTSTimelineViewDelegate;

@interface RTSTimelineView : UIView <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic) NSArray *events;

@property (nonatomic, weak) IBOutlet RTSMediaPlayerController *mediaPlayerController;

- (void) registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier;
- (void) registerNib:(UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier;

- (id) dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forEvent:(RTSTimelineEvent *)event;

@property (nonatomic, weak) IBOutlet id<RTSTimelineViewDataSource> dataSource;
@property (nonatomic, weak) IBOutlet id<RTSTimelineViewDelegate> delegate;

@end

@protocol RTSTimelineViewDataSource <NSObject>

- (UICollectionViewCell *) timelineView:(RTSTimelineView *)timelineView cellForEvent:(RTSTimelineEvent *)event;

@end

@protocol RTSTimelineViewDelegate <NSObject>

- (CGFloat) itemWidthForTimelineView:(RTSTimelineView *)timelineView;

@optional

- (CGFloat) itemSpacingForTimelineView:(RTSTimelineView *)timelineView;
- (void) timelineView:(RTSTimelineView *)timelineView didSelectEvent:(RTSTimelineEvent *)event;

@end

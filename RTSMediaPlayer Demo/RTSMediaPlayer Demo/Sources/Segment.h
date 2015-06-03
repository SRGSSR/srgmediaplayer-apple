//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <RTSMediaPlayer/RTSMediaPlayerSegment.h>
#import <UIKit/UIKit.h>

@interface Segment : NSObject <RTSMediaPlayerSegment>

- (instancetype)initWithTime:(CMTime)time title:(NSString *)title identifier:(NSString *)identifier date:(NSDate *)date;
- (instancetype)initWithStartTime:(NSTimeInterval)start duration:(NSTimeInterval)duration title:(NSString *)title blocked:(BOOL)blocked visible:(BOOL)visible;

@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly) UIImage *iconImage;
@property (nonatomic, readonly) NSURL *thumbnailURL;
@property (nonatomic, readonly) NSDate *date;

@end

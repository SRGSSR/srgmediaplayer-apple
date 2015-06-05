//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "Segment.h"

#pragma mark - Functions

static NSString *sexagesimalDurationStringFromValue(NSInteger duration)
{
	NSInteger hours = duration / 3600;
	NSInteger minutes = (duration % 3600) / 60;
	NSInteger seconds = (duration % 3600) % 60;
	
	NSString *minutesAndSeconds = [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
	
	return (hours > 0) ? [[NSString stringWithFormat:@"%01ld:", (long)hours] stringByAppendingString:minutesAndSeconds] : minutesAndSeconds;
}

@interface Segment ()

@property (nonatomic) CMTimeRange timeRange;
@property (nonatomic, copy) NSString *title;

@end

@implementation Segment

#pragma mark - Object lifecycle

- (instancetype) initWithTimeRange:(CMTimeRange)timeRange title:(NSString *)title
{
	self = [super init];
	if (self) {
		self.timeRange = timeRange;
		self.blocked = NO;
		self.visible = YES;
		
		self.title = title;
	}
	return self;
}

- (instancetype) initWithTime:(CMTime)time title:(NSString *)title
{
	return [self initWithTimeRange:CMTimeRangeMake(time, kCMTimeZero) title:title];
}

- (instancetype) initWithStart:(NSTimeInterval)start duration:(NSTimeInterval)duration title:(NSString *)title
{
	return [self initWithTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(start, 1.), CMTimeMakeWithSeconds(duration, 1.)) title:title];
}

#pragma mark - Getters and setters

- (NSURL *) thumbnailURL
{
	NSString *imageFilePath = [[NSBundle mainBundle] pathForResource:@"thumbnail-placeholder" ofType:@"png"];
	return [NSURL fileURLWithPath:imageFilePath];
}

- (NSString *) durationString
{
	return sexagesimalDurationStringFromValue(CMTimeGetSeconds(self.timeRange.duration));
}

- (NSString *) timestampString
{
	NSString *startString = sexagesimalDurationStringFromValue(CMTimeGetSeconds(self.timeRange.start));
	return [NSString stringWithFormat:@"%@ (%.0fs)", startString, CMTimeGetSeconds(self.timeRange.duration)];
}

#pragma mark - Description

- (NSString *) description
{
	return [NSString stringWithFormat:@"<%@: %p; time: %@; title: %@; blocked: %@; visible: %@>",
			[self class],
			self,
			@(CMTimeGetSeconds(self.timeRange.start)),
			self.title,
			self.blocked ? @"YES" : @"NO",
			self.visible ? @"YES" : @"NO"];
}

@end

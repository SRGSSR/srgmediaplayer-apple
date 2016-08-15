//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
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
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *segmentIdentifier;

@end

@implementation Segment

@synthesize logical = _logical;

#pragma mark - Object lifecycle

- (instancetype) initWithIdentifier:(NSString *)identifier name:(NSString *)name timeRange:(CMTimeRange)timeRange;
{
	self = [super init];
	if (self) {
		self.timeRange = timeRange;
		self.fullLength = NO;
		self.blocked = NO;
		self.visible = YES;
		self.logical = NO;
		
		self.segmentIdentifier = identifier;
		self.name = name;
	}
	return self;
}

- (instancetype) initWithIdentifier:(NSString *)identifier name:(NSString *)name time:(CMTime)time;
{
	return [self initWithIdentifier:identifier name:name timeRange:CMTimeRangeMake(time, kCMTimeZero)];
}

- (instancetype) initWithIdentifier:(NSString *)identifier name:(NSString *)name start:(NSTimeInterval)start duration:(NSTimeInterval)duration;
{
	return [self initWithIdentifier:identifier name:name timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(start, 1.), CMTimeMakeWithSeconds(duration, 1.))];
}

- (instancetype)init
{
	[self doesNotRecognizeSelector:_cmd];
	return [self initWithIdentifier:nil name:nil timeRange:kCMTimeRangeZero];
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
	return [NSString stringWithFormat:@"<%@: %p; start: %@; duration: %@; identifier: %@; name: %@; fullLength: %@; blocked: %@; visible: %@>",
			[self class],
			self,
			@(CMTimeGetSeconds(self.timeRange.start)),
			@(CMTimeGetSeconds(self.timeRange.duration)),
			self.segmentIdentifier,
			self.name,
			self.fullLength ? @"YES" : @"NO",
			self.blocked ? @"YES" : @"NO",
			self.visible ? @"YES" : @"NO"];
}

@end

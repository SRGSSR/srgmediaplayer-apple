//
//  RTSMediaPlayerControllerTestDataSource.m
//  RTSMediaPlayer
//
//  Created by Frédéric Humbert-Droz on 03/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSMediaPlayerTestDataSource.h"

@implementation RTSMediaPlayerTestDataSource

+ (NSURL *) contentURLForContentType:(RTSDataSourceTestContentType)contentType
{
	NSURL *contentURL = nil;
	
	switch (contentType)
	{
		case RTSDataSourceTestContentTypeAsset403Error:
		{
			contentURL = [NSURL URLWithString:@"http://httpbin.org/status/403"];
			break;
		}
		case RTSDataSourceTestContentTypeAsset404Error:
		{
			contentURL = [NSURL URLWithString:@"http://httpbin.org/status/404"];
			break;
		}
		case RTSDataSourceTestContentTypeAppleStreamingBasicSample:
		{
			contentURL = [NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"];
			break;
		}
		case RTSDataSourceTestContentTypeAppleStreamingAdvancedSample:
		{
			contentURL = [NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
			break;
		}
		default:
			break;
	}
	
	return contentURL;
}

+ (NSError *) errorForContentType:(RTSDataSourceTestContentType)contentType
{
	NSError *error = nil;
	switch (contentType)
	{
		case RTSDataSourceTestContentTypeContentURLError:
		{
			error = [NSError errorWithDomain:@"domain" code:0 userInfo:nil];
			break;
		}
		default:
			break;
	}
	
	return error;
}



#pragma mark - Initializer

- (instancetype) initWithContentType:(RTSDataSourceTestContentType)contentType
{
	if (!(self = [super init]))
		return nil;
	
	_contentType = contentType;
	
	return self;
}



#pragma mark - RTSMediaPlayerControllerDataSource

- (void) mediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController contentURLForIdentifier:(NSString *)identifier completionHandler:(void (^)(NSURL *contentURL, NSError *error))completionHandler
{
	NSError *error = [RTSMediaPlayerTestDataSource errorForContentType:self.contentType];
	if (error)
	{
		completionHandler(nil, error);
	}
	else if (self.contentType == RTSDataSourceTestContentTypeIdentifier)
	{
		completionHandler([NSURL URLWithString:identifier], nil);
	}
	else
	{
		completionHandler([RTSMediaPlayerTestDataSource contentURLForContentType:self.contentType], nil);
	}
}

@end

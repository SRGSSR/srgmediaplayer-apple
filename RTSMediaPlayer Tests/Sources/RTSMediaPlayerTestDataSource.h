//
//  RTSMediaPlayerControllerTestDataSource.h
//  RTSMediaPlayer
//
//  Created by Frédéric Humbert-Droz on 03/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RTSMediaPlayer/RTSMediaPlayerControllerDataSource.h>

typedef NS_ENUM(NSInteger, RTSDataSourceTestContentType)
{
	RTSDataSourceTestContentTypeContentURLError,
	
	RTSDataSourceTestContentTypeAsset403Error,
	RTSDataSourceTestContentTypeAsset404Error,
	
	RTSDataSourceTestContentTypeIdentifier,
	
	RTSDataSourceTestContentTypeAppleStreamingBasicSample,
	RTSDataSourceTestContentTypeAppleStreamingAdvancedSample,
};

@interface RTSMediaPlayerTestDataSource : NSObject <RTSMediaPlayerControllerDataSource>

+ (NSURL *) contentURLForContentType:(RTSDataSourceTestContentType)contentType;
+ (NSError *) errorForContentType:(RTSDataSourceTestContentType)contentType;

- (instancetype) initWithContentType:(RTSDataSourceTestContentType)contentType;

@property RTSDataSourceTestContentType contentType;

@end

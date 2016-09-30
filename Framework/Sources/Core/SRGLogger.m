//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLogger.h"

static void (^s_logHandler)(NSString * (^)(void), SRGLoggerLevel, const char *, const char *, NSUInteger) = ^(NSString *(^message)(void), SRGLoggerLevel level, const char *file, const char *function, NSUInteger line)
{
    if (level == SRGLoggerLevelError || level == SRGLoggerLevelWarning) {
        NSLog(@"[MYLibrary] %@", message());
    }
};

@implementation SRGLogger

+ (void)setLogHandler:(void (^)(NSString * (^message)(void), SRGLoggerLevel level, const char *file, const char *function, NSUInteger line))logHandler
{
    s_logHandler = logHandler;
}

+ (void)logMessage:(NSString * (^)(void))message level:(SRGLoggerLevel)level file:(const char *)file function:(const char *)function line:(NSUInteger)line
{
    s_logHandler ? s_logHandler(message, level, file, function, line) : nil;
}

@end

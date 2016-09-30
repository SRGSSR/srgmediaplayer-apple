//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGLogger.h"

static SRGLogHandler s_logHandler = ^(NSString *(^message)(void), SRGLogLevel level, const char *subsystem, const char *category, const char *file, const char *function, NSUInteger line)
{
    if (level == SRGLogLevelError || level == SRGLogLevelWarning) {
        if (category) {
            NSLog(@"[%s|%s] %@", subsystem, category, message());
        }
        else {
            NSLog(@"[%s] %@", subsystem, message());
        }
    }
};

@implementation SRGLogger

+ (void)setLogHandler:(SRGLogHandler)logHandler
{
    s_logHandler = logHandler;
}

+ (void)logMessage:(NSString * (^)(void))message
             level:(SRGLogLevel)level
         subsystem:(const char *)subsystem
          category:(const char *)category
              file:(const char *)file
          function:(const char *)function
              line:(NSUInteger)line
{
    s_logHandler ? s_logHandler(message, level, subsystem, category, file, function, line) : nil;
}

@end

//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SRGLogLevel) {
    SRGLogLevelVerbose,
    SRGLogLevelDebug,
    SRGLogLevelInfo,
    SRGLogLevelWarning,
    SRGLogLevelError
};

typedef void (^SRGLogHandler)(NSString * (^message)(void), SRGLogLevel level, const char *subsystem, const char *category, const char *file, const char *function, NSUInteger line);

// Entirely borrowed from Cédric Luthi with minor adjustements
// http://stackoverflow.com/questions/34732814/how-should-i-handle-logs-in-an-objective-c-library/34732815#
@interface SRGLogger : NSObject

+ (void)setLogHandler:(SRGLogHandler)logHandler;

+ (void)logMessage:(NSString * (^)(void))message
             level:(SRGLogLevel)level
         subsystem:(const char *)subsystem
          category:(const char *)category
              file:(const char *)file
          function:(const char *)function
              line:(NSUInteger)line;

@end

#define SRGLog(_subsystem, _category, _level, _message) [SRGLogger logMessage:(_message) level:(_level) subsystem:(_subsystem) category:(_category) file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__]

#define SRGLogVerbose(subsystem, category, format, ...) SRGLog(subsystem, category, SRGLogLevelVerbose, (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))
#define SRGLogDebug(subsystem, category, format, ...)   SRGLog(subsystem, category, SRGLogLevelDebug,   (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))
#define SRGLogInfo(subsystem, category, format, ...)    SRGLog(subsystem, category, SRGLogLevelInfo,    (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))
#define SRGLogWarning(subsystem, category, format, ...) SRGLog(subsystem, category, SRGLogLevelWarning, (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))
#define SRGLogError(subsystem, category, format, ...)   SRGLog(subsystem, category, SRGLogLevelError,   (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))

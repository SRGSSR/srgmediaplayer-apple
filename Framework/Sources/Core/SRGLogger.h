//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SRGLoggerLevel) {
    SRGLoggerLevelVerbose,
    SRGLoggerLevelDebug,
    SRGLoggerLevelInfo,
    SRGLoggerLevelWarning,
    SRGLoggerLevelError
};

// Entirely borrowed from Cédric Luthi
// http://stackoverflow.com/questions/34732814/how-should-i-handle-logs-in-an-objective-c-library/34732815#
@interface SRGLogger : NSObject

+ (void)setLogHandler:(void (^)(NSString * (^message)(void), SRGLoggerLevel level, const char *file, const char *function, NSUInteger line))logHandler;

+ (void)logMessage:(NSString * (^)(void))message level:(SRGLoggerLevel)level file:(const char *)file function:(const char *)function line:(NSUInteger)line;

@end

#define SRGLog(_level, _message) [SRGLogger logMessage:(_message) level:(_level) file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__]

#define SRGLogVerbose(format, ...) SRGLog(SRGLoggerLevelVerbose, (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))
#define SRGLogDebug(format, ...)   SRGLog(SRGLoggerLevelDebug,   (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))
#define SRGLogInfo(format, ...)    SRGLog(SRGLoggerLevelInfo,    (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))
#define SRGLogWarning(format, ...) SRGLog(SRGLoggerLevelWarning, (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))
#define SRGLogError(format, ...)   SRGLog(SRGLoggerLevelError,   (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))

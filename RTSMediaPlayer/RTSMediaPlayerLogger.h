//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <Foundation/Foundation.h>

/**
 *  Log levels (from CocoaLumberjack's DDLog.h)
 */
typedef NS_OPTIONS(NSUInteger, DDLogFlag){
	DDLogFlagError      = (1 << 0),
	DDLogFlagWarning    = (1 << 1),
	DDLogFlagInfo       = (1 << 2),
	DDLogFlagDebug      = (1 << 3),
	DDLogFlagVerbose    = (1 << 4),
	DDLogFlagTrace      = (1 << 5)			// custom level not present in DDLog.h
};

/**
 *  Internal minimal logger logging to the console, and compatible with CocoaLumberjack's DDLog interface
 */
@interface RTSMediaPlayerLogger : NSObject

+ (void) log:(BOOL)asynchronous level:(NSUInteger)level flag:(DDLogFlag)flag context:(NSInteger)context file:(const char *)file function:(const char *)function line:(NSUInteger)line tag:(id)tag format:(NSString *)format, ... NS_FORMAT_FUNCTION(9,10);

@end

/**
 *  Return the class used for logging (class compatible with DDLog interface). If DDLog is not available, an internal
 *  RTSMediaPlayerLogger class will be used (simply logging to the console)
 */
extern Class RTSMediaPlayerLogClass(void);

/**
 *  Common logger macro. A level must be specified
 */
#define RTSMediaPlayerLog(_flag, _format, ...) [RTSMediaPlayerLogClass() log:YES level:NSUIntegerMax flag:(_flag) context:0x5254536D file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__ tag:nil format:(_format), ##__VA_ARGS__]

/**
 *  Logger helper macros for the various log levels
 */
#define RTSMediaPlayerLogError(format, ...)   RTSMediaPlayerLog(DDLogFlagError,   format, ##__VA_ARGS__)
#define RTSMediaPlayerLogWarning(format, ...) RTSMediaPlayerLog(DDLogFlagWarning, format, ##__VA_ARGS__)
#define RTSMediaPlayerLogInfo(format, ...)    RTSMediaPlayerLog(DDLogFlagInfo,    format, ##__VA_ARGS__)
#define RTSMediaPlayerLogDebug(format, ...)   RTSMediaPlayerLog(DDLogFlagDebug,   format, ##__VA_ARGS__)
#define RTSMediaPlayerLogVerbose(format, ...) RTSMediaPlayerLog(DDLogFlagVerbose, format, ##__VA_ARGS__)
#define RTSMediaPlayerLogTrace(format, ...)   RTSMediaPlayerLog(DDLogFlagTrace,   format, ##__VA_ARGS__)

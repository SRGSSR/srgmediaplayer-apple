//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

/**
 *  Log levels (from CocoaLumberjack's DDLog.h)
 */
typedef NS_OPTIONS (NSUInteger, DDLogFlag) {
    DDLogFlagError      = (1 << 0),
    DDLogFlagWarning    = (1 << 1),
    DDLogFlagInfo       = (1 << 2),
    DDLogFlagDebug      = (1 << 3),
    DDLogFlagVerbose    = (1 << 4),
    DDLogFlagTrace      = (1 << 5)                      // custom level not present in DDLog.h
};

/**
 *  Internal minimal logger logging to the console, and compatible with CocoaLumberjack's DDLog interface
 */
@interface SRGMediaPlayerLogger : NSObject

+ (void)log:(BOOL)asynchronous level:(NSUInteger)level flag:(DDLogFlag)flag context:(NSInteger)context file:(const char *)file function:(const char *)function line:(NSUInteger)line tag:(id)tag format:(NSString *)format, ... NS_FORMAT_FUNCTION(9, 10);

@end

/**
 *  Return the class used for logging (class compatible with DDLog interface). If DDLog is not available, an internal
 *  SRGMediaPlayerLogger class will be used (simply logging to the console)
 */
extern Class SRGMediaPlayerLogClass(void);

/**
 *  Common logger macro. A level must be specified
 */
#define SRGMediaPlayerLog(_flag, _format, ...) [SRGMediaPlayerLogClass() log: YES level: NSUIntegerMax flag: (_flag)context : 0x5254536D file: __FILE__ function: __PRETTY_FUNCTION__ line: __LINE__ tag: nil format: (_format), ## __VA_ARGS__]

/**
 *  Logger helper macros for the various log levels
 */
#define SRGMediaPlayerLogError(format, ...)   SRGMediaPlayerLog(DDLogFlagError,   format, ## __VA_ARGS__)
#define SRGMediaPlayerLogWarning(format, ...) SRGMediaPlayerLog(DDLogFlagWarning, format, ## __VA_ARGS__)
#define SRGMediaPlayerLogInfo(format, ...)    SRGMediaPlayerLog(DDLogFlagInfo,    format, ## __VA_ARGS__)
#define SRGMediaPlayerLogDebug(format, ...)   SRGMediaPlayerLog(DDLogFlagDebug,   format, ## __VA_ARGS__)
#define SRGMediaPlayerLogVerbose(format, ...) SRGMediaPlayerLog(DDLogFlagVerbose, format, ## __VA_ARGS__)
#define SRGMediaPlayerLogTrace(format, ...)   SRGMediaPlayerLog(DDLogFlagTrace,   format, ## __VA_ARGS__)

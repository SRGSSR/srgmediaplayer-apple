//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <Foundation/Foundation.h>

// From CocoaLumberjack's DDLog.h
typedef NS_OPTIONS(NSUInteger, DDLogFlag) {
	DDLogFlagError      = (1 << 0), // 0...00001
	DDLogFlagWarning    = (1 << 1), // 0...00010
	DDLogFlagInfo       = (1 << 2), // 0...00100
	DDLogFlagDebug      = (1 << 3), // 0...01000
	DDLogFlagVerbose    = (1 << 4), // 0...10000
	DDLogFlagTrace      = (1 << 5)  // 0..100000 (custom level not present in DDLog.h)
};

@interface RTSMediaPlayerLogger : NSObject
// Compatible with CocoaLumberjack's DDLog interface
+ (void) log:(BOOL)asynchronous level:(NSUInteger)level flag:(DDLogFlag)flag context:(NSInteger)context file:(const char *)file function:(const char *)function line:(NSUInteger)line tag:(id)tag format:(NSString *)format, ... NS_FORMAT_FUNCTION(9,10);
@end

extern Class RTSMediaPlayerLogClass(void);

#define RTSMediaPlayerLog(_flag, _format, ...) [RTSMediaPlayerLogClass() log:YES level:NSUIntegerMax flag:(_flag) context:0x5254536D file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__ tag:nil format:(_format), ##__VA_ARGS__]

#define RTSMediaPlayerLogError(format, ...)   RTSMediaPlayerLog(DDLogFlagError,   format, ##__VA_ARGS__)
#define RTSMediaPlayerLogWarning(format, ...) RTSMediaPlayerLog(DDLogFlagWarning, format, ##__VA_ARGS__)
#define RTSMediaPlayerLogInfo(format, ...)    RTSMediaPlayerLog(DDLogFlagInfo,    format, ##__VA_ARGS__)
#define RTSMediaPlayerLogDebug(format, ...)   RTSMediaPlayerLog(DDLogFlagDebug,   format, ##__VA_ARGS__)
#define RTSMediaPlayerLogVerbose(format, ...) RTSMediaPlayerLog(DDLogFlagVerbose, format, ##__VA_ARGS__)
#define RTSMediaPlayerLogTrace(format, ...)   RTSMediaPlayerLog(DDLogFlagTrace,   format, ##__VA_ARGS__)

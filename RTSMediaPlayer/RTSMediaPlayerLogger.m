//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RTSMediaPlayerLogger.h"

#pragma clang diagnostic ignored "-Wformat-nonliteral"

@implementation RTSMediaPlayerLogger

+ (void) log:(BOOL)asynchronous level:(NSUInteger)level flag:(DDLogFlag)flag context:(NSInteger)context file:(const char *)file function:(const char *)function line:(NSUInteger)line tag:(id)tag format:(NSString *)format, ...
{
	char *logLevelString = getenv("RTSMediaPlayerLogLevel");
	NSUInteger logLevel = logLevelString ? strtoul(logLevelString, NULL, 0) : DDLogFlagError | DDLogFlagWarning;
	if (!(flag & logLevel))
		return;
	
	va_list arguments;
	va_start(arguments, format);
	NSLog(@"[RTSMediaPlayer] %@", [[NSString alloc] initWithFormat:format arguments:arguments]);
	va_end(arguments);
}

@end

Class RTSMediaPlayerLogClass(void)
{
	static Class logClass;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		logClass = NSClassFromString(@"DDLog");
		if (![logClass methodSignatureForSelector:@selector(log:level:flag:context:file:function:line:tag:format:)])
			logClass = [RTSMediaPlayerLogger class];
	});
	return logClass;
}

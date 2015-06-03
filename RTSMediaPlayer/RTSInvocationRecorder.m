//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import "RTSInvocationRecorder.h"

@interface RTSInvocationRecorder ()
@property (readonly) Class targetClass;
@property (readonly) NSMutableArray *mutableInvocations;
@end

@implementation RTSInvocationRecorder

- (instancetype) initWithTargetClass:(Class)targetClass;
{
	_targetClass = targetClass;
	_mutableInvocations = [NSMutableArray new];
	return self;
}

- (NSMethodSignature *) methodSignatureForSelector:(SEL)selector
{
	return [self.targetClass instanceMethodSignatureForSelector:selector];
}

- (void) forwardInvocation:(NSInvocation *)invocation
{
	if ([@([[invocation methodSignature] methodReturnType]) isEqualToString:@(@encode(void))])
		[self.mutableInvocations addObject:invocation];
	else
		NSLog(@"Warning: invocation does not have a void return type, returning nil/0 for %@.", NSStringFromSelector(invocation.selector));
}

- (BOOL) respondsToSelector:(SEL)selector
{
	return [self.targetClass instancesRespondToSelector:selector];
}

- (NSArray *) invocations
{
	return [NSArray arrayWithArray:self.mutableInvocations];
}

- (NSString *) debugDescription
{
	NSMutableString *debugDescription = [NSMutableString stringWithFormat:@"<%@(%@): %p>\n", self.class, self.targetClass, self];
	for (NSInvocation *invocation in self.invocations)
		[debugDescription appendString:invocation.debugDescription];
	return [debugDescription copy];
}

@end

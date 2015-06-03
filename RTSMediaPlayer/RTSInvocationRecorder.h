//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <Foundation/Foundation.h>

@interface RTSInvocationRecorder : NSProxy

- (instancetype) initWithTargetClass:(Class)targetClass;

@property (readonly) NSArray *invocations;

@end

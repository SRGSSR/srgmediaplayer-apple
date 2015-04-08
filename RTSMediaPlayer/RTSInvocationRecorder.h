//
//  Created by Cédric Luthi on 08.04.15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RTSInvocationRecorder : NSProxy

- (instancetype) initWithTargetClass:(Class)targetClass;

@property (readonly) NSArray *invocations;

@end

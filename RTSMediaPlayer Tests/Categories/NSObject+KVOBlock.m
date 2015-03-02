//
//  NSObject+KVOBlock.m
//  RTSMediaPlayer
//
//  Created by Frédéric Humbert-Droz on 02/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "NSObject+KVOBlock.h"

@implementation NSObject (KVOBlock)

- (void)observeKeyPath:(NSString *)keyPath withBlock:(void (^)(id, NSString *, NSDictionary *))block
{
	[self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionInitial context:(__bridge void *)(block)];
}

- (void) unobserveKeyPath:(NSString *)keyPath
{
	[self removeObserver:self forKeyPath:keyPath];
}

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
	void (^block)(id, NSString *, NSDictionary*) = (__bridge void (^)(id, NSString *, NSDictionary *))context;
	block(self, keyPath, change);
}

@end

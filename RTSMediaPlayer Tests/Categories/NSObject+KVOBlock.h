//
//  NSObject+KVOBlock.h
//  RTSMediaPlayer
//
//  Created by Frédéric Humbert-Droz on 02/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (KVOBlock)

// invoke the block when the receiver's value at keyPath changes
// block params are the receiver, the keyPath and the old value
- (void)observeKeyPath:(NSString *)keyPath withBlock:(void (^)(id, NSString *, NSDictionary *))block;
- (void)unobserveKeyPath:(NSString *)keyPath;

@end

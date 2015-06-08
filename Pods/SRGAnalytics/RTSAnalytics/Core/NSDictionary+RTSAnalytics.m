//
//  NSDictionary+Utils.m
//  RTSAnalytics
//
//  Created by Cédric Foellmi on 26/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "NSDictionary+RTSAnalytics.h"

@implementation NSDictionary (RTSAnalytics)

- (void)safeSetValue:(id)value forKey:(NSString *)key
{
    if (value && key) {
        [self setValue:value forKey:key];
    }
}

@end

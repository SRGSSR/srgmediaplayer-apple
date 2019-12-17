//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Resources.h"

NSString *ResourceNameForUIClass(Class cls)
{
    NSString *name = NSStringFromClass(cls);
#if TARGET_OS_TV
    return [name stringByAppendingString:@"~tvos"];
#else
    return [name stringByAppendingString:@"~ios"];
#endif
}

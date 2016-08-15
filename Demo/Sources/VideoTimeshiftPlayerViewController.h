//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <UIKit/UIKit.h>

@interface VideoTimeshiftPlayerViewController : UIViewController 

@property (nonatomic, strong) NSURL *mediaURL;
@property (nonatomic, assign) BOOL tokenizeMediaURL;

@end

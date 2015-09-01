//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <UIKit/UIKit.h>

@interface VideoTimeshiftPlayerViewController : UIViewController 

@property (nonatomic, strong) NSURL *mediaURL;
@property (nonatomic, assign) BOOL tokenizeMediaURL;

@end

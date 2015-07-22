//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <UIKit/UIKit.h>

#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface DemoInlineViewController : UIViewController <RTSMediaPlayerControllerDataSource>

@property (nonatomic, weak) IBOutlet UIView *videoContainerView;
@property (nonatomic, strong) IBOutlet RTSMediaPlayerController *mediaPlayerController;

@property (nonatomic, strong) NSURL *mediaURL;

@end

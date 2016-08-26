//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface DemoInlineViewController : UIViewController <RTSMediaPlayerControllerDataSource>

@property (nonatomic, weak) IBOutlet UIView *videoContainerView;
@property (nonatomic, strong) IBOutlet SRGMediaPlayerController *mediaPlayerController;

@property (nonatomic, strong) NSURL *mediaURL;

@end

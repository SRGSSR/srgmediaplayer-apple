//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <RTSMediaPlayer/RTSMediaPlayer.h>
#import <UIKit/UIKit.h>

@interface DemoTimelineViewController : UIViewController <RTSTimelineSliderDelegate, RTSTimelineViewDelegate>

@property (nonatomic, copy) NSString *videoIdentifier;

@end

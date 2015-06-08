//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <RTSMediaPlayer/RTSMediaPlayer.h>
#import <UIKit/UIKit.h>

@interface DemoSegmentsBlockingViewController : UIViewController <RTSTimelineSliderDelegate, RTSSegmentedTimelineViewDelegate>

@property (nonatomic, copy) NSString *videoIdentifier;

@end

//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <UIKit/UIKit.h>

@interface DemoTimelineViewController : UIViewController <RTSTimelineSliderDelegate, RTSSegmentedTimelineViewDelegate>

@property (nonatomic, copy) NSString *videoIdentifier;

@end

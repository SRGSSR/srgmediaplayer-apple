//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <UIKit/UIKit.h>

@interface DemoTimelineViewController : UIViewController <RTSTimelineSliderDelegate, RTSSegmentedTimelineViewDelegate>

@property (nonatomic, copy) NSString *videoIdentifier;

@end

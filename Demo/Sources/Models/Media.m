//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Media.h"

@interface Media ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic) NSURL *URL;
@property (nonatomic) BOOL is360;

@property (nonatomic) NSArray<MediaSegment *> *segments;

@end

@implementation Media

+ (NSArray<Media *> *)mediasFromFileAtPath:(NSString *)filePath
{
    NSArray<NSDictionary *> *mediaDictionaries = [NSDictionary dictionaryWithContentsOfFile:filePath][@"medias"];
    
    NSMutableArray<Media *> *medias = [NSMutableArray array];
    for (NSDictionary *mediaDictionary in mediaDictionaries) {
        Media *media = [[self alloc] initWithDictionary:mediaDictionary];
        if (media) {
            [medias addObject:media];
        }
    }
    return medias.copy;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        self.name = dictionary[@"name"];
        if (! self.name) {
            return nil;
        }
        
        NSString *URLString = dictionary[@"url"];
        self.URL = URLString ? [NSURL URLWithString:URLString] : nil;
        if (! self.URL) {
            return nil;
        }
        
        self.is360 = [dictionary[@"is360"] boolValue];
        
        NSMutableArray<MediaSegment *> *segments = [NSMutableArray array];
        for (NSDictionary *segmentDictionary in dictionary[@"segments"]) {
            MediaSegment *segment = [[MediaSegment alloc] initWithDictionary:segmentDictionary];
            [segments addObject:segment];
        }
        self.segments = segments.copy;
    }
    return self;
}

@end

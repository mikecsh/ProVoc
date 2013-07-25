//
//  SoundRecorderController.m
//  ProVoc
//
//  Created by Mike Holman on 25/07/2013.
//
//

#import "SoundRecorderController.h"

@implementation SoundRecorderController

+ (SoundRecorderController *)sharedGrabber;
{
    return [[NSObject alloc] init];
}

- (NSString *)captureMovie;
{
    return @"";
}

- (NSImage *)captureImage;
{
    return @"";
}

@end

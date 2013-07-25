//
//  SoundRecorderController.h
//  ProVoc
//
//  Created by Mike Holman on 25/07/2013.
//
//

#import <Foundation/Foundation.h>

@interface SoundRecorderController : NSObject

+ (SoundRecorderController *)sharedGrabber;
- (NSString *)captureMovie;
- (NSImage *)captureImage;

@end

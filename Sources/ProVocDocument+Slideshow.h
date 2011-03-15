//
//  ProVocDocument+Slideshow.h
//  ProVoc
//
//  Created by Simon Bovet on 06.04.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ProVocDocument.h"

#define PVSlideshowAutoAdvance @"slideshowAutoAdvance"
#define PVSlideshowSpeed @"slideshowSpeed"
#define PVSlideshowRandom @"slideshowRandom"

@interface ProVocDocument (Slideshow)

-(void)slideshowWithWords:(NSArray *)inWords;

@end

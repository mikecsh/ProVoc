//
//  ImageExtensions.h
//  ProVoc
//
//  Created by Simon Bovet on 09.01.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSImage (Extensions)

-(void)drawScaledProportionallyInRect:(NSRect)inRect fraction:(float)inFraction;

@end

@interface NSImage (Badge)

+(NSImage *)badgeImageWithNumber:(int)inNumber;

@end

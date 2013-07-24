//
//  ProVocColoredWindowView.h
//  ProVoc
//
//  Created by Simon Bovet on 16.03.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ProVocColoredWindowView : NSView {
	NSColor *mColor;
}

-(void)setColor:(NSColor *)inColor;

@end

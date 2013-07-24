//
//  ProVocColoredWindowView.m
//  ProVoc
//
//  Created by Simon Bovet on 16.03.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ProVocColoredWindowView.h"


@implementation ProVocColoredWindowView

-(void)dealloc
{
	[mColor release];
	[super dealloc];
}

-(void)setColor:(NSColor *)inColor
{
	if (![mColor isEqual:inColor]) {
		[mColor release];
		mColor = [inColor retain];
		[self setNeedsDisplay:YES];
	}
}

-(void)drawRect:(NSRect)inRect
{
	[super drawRect:inRect];
	if (mColor) {
		[[mColor colorWithAlphaComponent:0.75] set];
		[NSBezierPath fillRect:inRect];
	}
}

@end

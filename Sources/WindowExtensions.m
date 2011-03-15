//
//  WindowExtensions.m
//  ProVoc
//
//  Created by Simon Bovet on 08.10.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import "WindowExtensions.h"

#import "ProVocBackground.h"

@implementation NSWindow (Shake)

-(void)shake
{
	ProVocBackground *background = [ProVocBackground sharedBackground];
	NSPoint origin = [self frame].origin;
	NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0.2];
	int r = 14;
	int s = 1;
	while ([date timeIntervalSinceNow] > 0) {
		[self setFrameOrigin:NSMakePoint(origin.x + s * (rand() % r + 1), origin.y)];
		s *= -1;
		[background displayNow];
	}
	[self setFrameOrigin:origin];
}

-(void)setContentSize:(NSSize)inSize keepTopLeftCorner:(BOOL)inKeepTopLeftCorner
{
	NSRect frameRect = [self frame];
	NSPoint topLeftCorner = NSMakePoint(NSMinX(frameRect), NSMaxY(frameRect));
	[self setContentSize:inSize];
	if (inKeepTopLeftCorner)
		[self setFrameTopLeftPoint:topLeftCorner];
}

@end

@implementation NSView (ClassSubview)

-(NSView *)subviewOfClass:(Class)inClass
{
	if ([self isKindOfClass:inClass])
		return self;
	NSEnumerator *enumerator = [[self subviews] objectEnumerator];
	NSView *subview;
	while (subview = [enumerator nextObject]) {
		NSView *view = [subview subviewOfClass:inClass];
		if (view)
			return view;
	}
	return nil;
}

@end


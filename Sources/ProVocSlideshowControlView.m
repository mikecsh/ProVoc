//
//  ProVocSlideshowControlView.m
//  ProVoc
//
//  Created by Simon Bovet on 12.10.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ProVocSlideshowControlView.h"
#import "BezierPathExtensions.h"


@interface ProVocSlideshowControlView (Private)

-(void)cancelIdlingCalls;

@end

@implementation ProVocSlideshowControlView

-(NSBezierPath *)pathForPlay
{
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(-24, 27)];
	[path lineToPoint:NSMakePoint(30, 0)];
	[path lineToPoint:NSMakePoint(-24, -27)];
	[path closePath];
	return path;
}

-(NSBezierPath *)pathForPause
{
	NSRect r = NSMakeRect(0, 0, 17, 54);
	NSBezierPath *path = [NSBezierPath bezierPath];
	r.origin.y -= r.size.height / 2;
	r.origin.x = 6;
	[path appendBezierPathWithRect:r];
	r.origin.x = -r.origin.x - r.size.width;
	[path appendBezierPathWithRect:r];
	return path;
}

-(id)initWithFrame:(NSRect)inFrame
{
    if (self = [super initWithFrame:inFrame]) {
		NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
		[dictionary setObject:[self pathForPlay] forKey:@"Play"];
		[dictionary setObject:[self pathForPause] forKey:@"Pause"];
		mControlPaths = [dictionary copy];
		mControls = [[NSMutableArray alloc] initWithObjects:@"Play", nil];
    }
    return self;
}

-(void)dealloc
{
	[mControlPaths release];
	[mControls release];
	[mHighlight release];
	[super dealloc];
}

-(void)drawRect:(NSRect)inRect
{
	[[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] set];
	[[NSBezierPath bezierPathWithRoundRectInRect:[self bounds] radius:22] fill];
	
	NSEnumerator *enumerator = [mControls objectEnumerator];
	id control;
	int x = 0;
	while (control = [enumerator nextObject]) {
		[NSGraphicsContext saveGraphicsState];
		NSAffineTransform *transform = [NSAffineTransform transform];
		[transform translateXBy:NSMidX([self bounds]) + x * 66 yBy:NSMidY([self bounds])];
		[transform concat];
		BOOL highlight = [mHighlight isEqual:control];
		if (highlight) {
			[[NSColor colorWithCalibratedWhite:1.0 alpha:0.8] set];
			NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
			[shadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.8]];
			[shadow setShadowOffset:NSZeroSize];
			[shadow setShadowBlurRadius:5];
			[shadow set];
		} else
			[[NSColor colorWithCalibratedWhite:1.0 alpha:0.3] set];
		[[mControlPaths objectForKey:control] fill];
		[NSGraphicsContext restoreGraphicsState];
		x++;
	}
}

-(BOOL)isOpaque
{
	return NO;
}

-(void)highlightControl:(id)inControl
{
	if (mHighlight != inControl) {
		[mHighlight release];
		mHighlight = [inControl retain];
		if (![mControls containsObject:mHighlight])
			[mControls replaceObjectAtIndex:0 withObject:mHighlight];
		[self display];
	}
	[[self window] setAlphaValue:1.0];
	[self cancelIdlingCalls];
	[self performSelector:@selector(fadeOut:) withObject:nil afterDelay:1.5];
}

-(void)setControl:(id)inControl
{
	if (![mControls containsObject:inControl]) {
		[mControls replaceObjectAtIndex:1 withObject:inControl];
		[self setNeedsDisplay:YES];
	}
}

-(void)cancelIdlingCalls
{
	[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(fadeOut:) object:nil];
}

-(void)fadeOut:(id)inSender
{
	NSWindow *window = [self window];
	float alpha = [window alphaValue];
	alpha = MAX(0, alpha - 0.1);
	[window setAlphaValue:alpha];
	if (alpha > 0)
		[self performSelector:@selector(fadeOut:) withObject:nil afterDelay:0.05];
}

@end

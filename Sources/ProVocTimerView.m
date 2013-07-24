//
//  ProVocTimerView.m
//  ProVoc
//
//  Created by Simon Bovet on 15.05.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ProVocTimerView.h"

#import "TransformerExtensions.h"
#import "StringExtensions.h"

@implementation ProVocTimerView

-(void)setTime:(NSTimeInterval)inTime
{
	mTime = MAX(0.0, MIN(99 * 60 + 59, inTime));
	[self setNeedsDisplay:YES];
}

-(void)setCountingDown:(BOOL)inCountingDown
{
	mCountingDown = inCountingDown;
	[self setNeedsDisplay:YES];
}

-(void)drawRect:(NSRect)inRect
{
	[[NSColor whiteColor] set];
	NSFrameRect([self bounds]);
	
	NSRect imageRect, stringRect;
	NSDivideRect([self bounds], &imageRect, &stringRect, [self bounds].size.height, NSMinXEdge);
	NSImage *image = [NSImage imageNamed:mCountingDown ? @"Hourglass" : @"Clock"];
	NSPoint pt;
	pt.x = NSMidX(imageRect);
	pt.y = NSMidY(imageRect);
	pt.x = round(pt.x - [image size].width / 2);
	pt.y = round(pt.y - [image size].height / 2) - 1;
	[image dissolveToPoint:pt fraction:1.0];
	
	static NSDictionary *attributes = nil;
	static TimerDurationTransformer *transformer;
	if (!attributes) {
		NSFont *font = [NSFont systemFontOfSize:24];
		font = [[NSFontManager sharedFontManager] convertFont:font toFamily:@"American Typewriter"];
		NSMutableParagraphStyle *paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
		[paragraphStyle setAlignment:NSLeftTextAlignment /*NSCenterTextAlignment*/];
		attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSColor whiteColor], NSForegroundColorAttributeName,
																	font, NSFontAttributeName,
																	paragraphStyle, NSParagraphStyleAttributeName,
																	nil];
		transformer = [[TimerDurationTransformer alloc] init];
	}
	NSAttributedString *string = [[NSAttributedString alloc] initWithString:[transformer transformedValue:[NSNumber numberWithFloat:mTime]] attributes:attributes];
	stringRect.size.height = [string heightForWidth:stringRect.size.width];
	stringRect.origin.y = round(NSMidY([self bounds]) - stringRect.size.height / 2 + 5);
	stringRect.size.height += 20;
	stringRect.origin.y -= 20;
	[string drawInRect:stringRect];
	[string release];
}

@end

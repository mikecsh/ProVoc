//
//  ProVocResultView.m
//  ProVoc
//
//  Created by Simon Bovet on 25.02.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ProVocResultView.h"

#import "BezierPathExtensions.h"

#define TITLE_KEY @"Title"
#define VALUE_KEY @"Value"
#define COLOR_KEY @"Color"

@implementation ProVocResultView

-(void)dealloc
{
	[mResults release];
	[super dealloc];
}

-(float)positionToRadian:(float)inPosition
{
	return M_PI / 2 - inPosition / mTotal * 2 * M_PI;
}

-(float)positionToDegrees:(int)inPosition
{
	return 90 - (float)inPosition / mTotal * 360;
}

-(void)drawPieFrom:(int)inFrom to:(int)inTo title:(NSString *)inTitle number:(int)inNumber color:(NSColor *)inColor
{
	if (inFrom == inTo)
		return;
	BOOL total = inFrom == 0 && inTo == mTotal;
	
	float angle = 0.5 * ([self positionToRadian:inFrom] + [self positionToRadian:inTo]);
	float delta = total ? 0 : 10;
	NSPoint origin = NSMakePoint(NSMidX([self bounds]), NSMidY([self bounds]));
	origin.x = round(origin.x + cos(angle) * delta);
	origin.y = round(origin.y + sin(angle) * delta);
	float radius = round(MIN([self bounds].size.width, [self bounds].size.height) / 2 - 15); 
	
	if (!inTitle) {
		NSBezierPath *bezierPath = [NSBezierPath bezierPath];
		if (total)
			[bezierPath appendBezierPathWithOvalInRect:NSMakeRect(origin.x - radius, origin.y - radius, 2 * radius, 2 * radius)];
		else {
			[bezierPath moveToPoint:origin];
			[bezierPath appendBezierPathWithArcWithCenter:origin radius:radius
					startAngle:[self positionToDegrees:inFrom] endAngle:[self positionToDegrees:inTo] clockwise:YES];
			[bezierPath closePath];
		}
		NSArray *colors = @[inColor, [inColor blendedColorWithFraction:0.25 ofColor:[NSColor blackColor]]];
		[bezierPath fillWithColors:colors angleInDegrees:-90];
		[[NSColor blackColor] set];
		[bezierPath setLineWidth:2.0];
		[bezierPath stroke];
	}
	
	if (inTitle) {
		static NSDictionary *attributes = nil;
		if (!attributes) {
			NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
			[paragraphStyle setAlignment:NSCenterTextAlignment];
			NSShadow *shadow = [[NSShadow alloc] init];
			[shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0]];
			[shadow setShadowBlurRadius:3.0];
			[shadow setShadowOffset:NSMakeSize(2.0, -2.0)];
			attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont boldSystemFontOfSize:0], NSFontAttributeName,
															[NSColor whiteColor], NSForegroundColorAttributeName,
															paragraphStyle, NSParagraphStyleAttributeName,
															shadow, NSShadowAttributeName,
															nil];
			[paragraphStyle release];
			[shadow release];
		}
		
		NSString *title = [NSString stringWithFormat:@"%@\n%i", inTitle, inNumber];
		if (total)
			radius = 0;
		else
			radius *= abs([self positionToDegrees:inFrom] - [self positionToDegrees:inTo]) >= 180 ? 0.5 : 0.67;
		NSRect rect;
		rect.origin.x = origin.x + cos(angle) * radius;
		rect.origin.y = origin.y + sin(angle) * radius;
		rect.size = [title sizeWithAttributes:attributes];
		rect.origin.x -= rect.size.width / 2;
		rect.origin.y -= rect.size.height / 2;
		rect.size.height += 20;
		rect.origin.y -= 20;
		[title drawInRect:rect withAttributes:attributes];
	}
}

-(void)drawRect:(NSRect)inRect
{
	int layer;
	for (layer = 0; layer < 2; layer++) {
		NSEnumerator *enumerator = [mResults objectEnumerator];
		NSDictionary *result;
		int from = 0;
		while (result = [enumerator nextObject]) {
			int n = [result[VALUE_KEY] intValue];
			[self drawPieFrom:from to:from + n title:layer == 1 ? result[TITLE_KEY] : nil number:n color:result[COLOR_KEY]];
			from += n;
		}
	}
}

-(void)removeResults
{
	[mResults release];
	mResults = nil;
	mTotal = 0;
}

-(void)addResult:(NSString *)inTitle value:(int)inValue color:(NSColor *)inColor
{
	if (!mResults)
		mResults = [[NSMutableArray alloc] initWithCapacity:0];
	[mResults addObject:@{TITLE_KEY: inTitle, VALUE_KEY: @(inValue), COLOR_KEY: inColor}];
	mTotal += inValue;
	[self setNeedsDisplay:YES];
}

@end

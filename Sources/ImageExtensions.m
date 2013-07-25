//
//  ImageExtensions.m
//  ProVoc
//
//  Created by Simon Bovet on 09.01.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ImageExtensions.h"


@implementation NSImage (Extensions)

-(void)drawScaledProportionallyInRect:(NSRect)inRect fraction:(float)inFraction
{
	NSRect src = NSZeroRect;
	src.size = [self size];
	float factor = MIN(inRect.size.width / src.size.width, inRect.size.height / src.size.height);
	NSRect dst;
	dst.size.width = factor * src.size.width;
	dst.size.height = factor * src.size.height;
	dst.origin.x = NSMidX(inRect) - dst.size.width / 2;
	dst.origin.y = NSMidY(inRect) - dst.size.height / 2;
	[self drawInRect:dst fromRect:src operation:NSCompositeSourceOver fraction:inFraction];
}

@end

@implementation NSImage (Badge)

+(NSImage *)badgeImageWithNumber:(int)inNumber
{
	static NSMutableAttributedString *string = nil;
	if (!string) {
		NSMutableParagraphStyle *paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
		[paragraphStyle setAlignment:NSCenterTextAlignment];
		NSFont *font = [[NSFontManager sharedFontManager] convertFont:[NSFont fontWithName:@"Arial" size:14] toHaveTrait:NSBoldFontMask];
		NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
					font, NSFontAttributeName,
					[NSColor whiteColor], NSForegroundColorAttributeName,
					paragraphStyle, NSParagraphStyleAttributeName,
					nil];
		string = [[NSMutableAttributedString alloc] initWithString:@"?" attributes:attributes];
	}
	[string replaceCharactersInRange:NSMakeRange(0, [string length]) withString:[NSString stringWithFormat:@"%i", inNumber]];
	NSSize size = [string size];
	int verticalInset = 4;
	size.width += 7;
	size.height += 2 * verticalInset;
	
	float badgeMaxRadius = size.height / 2;
	float badgeMinRadius = badgeMaxRadius - 2;
	int starNumber = 28;
	float horizontalEpsilon = badgeMaxRadius * 2 * M_PI / starNumber;
	
	NSSize badgeSize = size;
	int horizontalPoints = MAX(0, ceil((badgeSize.width - badgeSize.height) / horizontalEpsilon));
	if (horizontalPoints > 0)
		horizontalPoints += 2;
	badgeSize.width = badgeSize.height + horizontalPoints * horizontalEpsilon;
	
	NSImage *image = [[[NSImage alloc] initWithSize:badgeSize] autorelease];
	[image lockFocus];
	
	NSBezierPath *bezierPath = [NSBezierPath bezierPath];
	int i;
	NSPoint center = NSMakePoint(badgeSize.width - badgeMaxRadius, badgeSize.height / 2);
	[bezierPath moveToPoint:NSMakePoint(center.x, center.y + badgeMaxRadius)];
	for (i = 0; i < starNumber / 2; i++) {
		float a = M_PI * (0.5 - (i * 2.0 + 1) / starNumber);
		[bezierPath lineToPoint:NSMakePoint(center.x + badgeMinRadius * cos(a), center.y + badgeMinRadius * sin(a))];
		a -= M_PI / starNumber;
		[bezierPath lineToPoint:NSMakePoint(center.x + badgeMaxRadius * cos(a), center.y + badgeMaxRadius * sin(a))];
	}

	for (i = 0; i < horizontalPoints; i++) {
		[bezierPath relativeLineToPoint:NSMakePoint(-horizontalEpsilon / 2, badgeMaxRadius - badgeMinRadius)];
		[bezierPath relativeLineToPoint:NSMakePoint(-horizontalEpsilon / 2, badgeMinRadius - badgeMaxRadius)];
	}
	
	center = NSMakePoint(badgeMaxRadius, badgeSize.height / 2);
	for (i = starNumber / 2; i < starNumber; i++) {
		float a = M_PI * (0.5 - (i * 2.0 + 1) / starNumber);
		[bezierPath lineToPoint:NSMakePoint(center.x + badgeMinRadius * cos(a), center.y + badgeMinRadius * sin(a))];
		a -= M_PI / starNumber;
		[bezierPath lineToPoint:NSMakePoint(center.x + badgeMaxRadius * cos(a), center.y + badgeMaxRadius * sin(a))];
	}
	
	for (i = 0; i < horizontalPoints; i++) {
		[bezierPath relativeLineToPoint:NSMakePoint(horizontalEpsilon / 2, badgeMinRadius - badgeMaxRadius)];
		[bezierPath relativeLineToPoint:NSMakePoint(horizontalEpsilon / 2, badgeMaxRadius - badgeMinRadius)];
	}
	[bezierPath closePath];
	
	[[NSColor redColor] set];
	static NSShadow *shadow = nil;
	if (!shadow) {
		shadow = [[NSShadow alloc] init];
		[shadow setShadowColor:[NSColor colorWithCalibratedWhite:0 alpha:0.5]];
		[shadow setShadowOffset:NSMakeSize(1, -1)];
		[shadow setShadowBlurRadius:2];
	}
	[NSGraphicsContext saveGraphicsState];
	[shadow set];
	[bezierPath fill];
	[NSGraphicsContext restoreGraphicsState];

	[string drawInRect:NSInsetRect(NSMakeRect(0, 4 - 10, badgeSize.width, badgeSize.height + 10), 2, verticalInset)];
	[image unlockFocus];
	return image;
}

@end


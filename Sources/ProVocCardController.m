//
//  ProVocCardController.m
//  ProVoc
//
//  Created by Simon Bovet on 12.05.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ProVocCardController.h"

#import "ProVocDocument.h"
#import "ProVocWord.h"
#import "ProVocInspector.h"

#import "ProVocCardsView.h"

@implementation ProVocCardController

-(id)initWithDocument:(ProVocDocument *)inDocument words:(NSArray *)inWords
{
	if (self = [super initWithWindowNibName:@"ProVocCardController"]) {
		[self loadWindow];
		mDocument = [inDocument retain];
		mWords = [inWords retain];
		
		NSEnumerator *enumerator = [mWords objectEnumerator];
		ProVocWord *word;
		mWordIndex = 0;
		while (word = [enumerator nextObject]) {
			mWordIndex++;
			if ([word imageMedia]) {
				[self willChangeValueForKey:@"containImages"];
				mContainImages = YES;
				[self didChangeValueForKey:@"containImages"];
				break;
			}
		}
		if (!mContainImages)
			mWordIndex = 1;

		enumerator = [mWords objectEnumerator];
		while (word = [enumerator nextObject])
			if ([[word comment] length] > 0) {
				[self willChangeValueForKey:@"containComments"];
				mContainComments = YES;
				[self didChangeValueForKey:@"containComments"];
				break;
			}
	}
	return self;
}

-(void)dealloc
{
	[mDocument release];
	[mWords release];
	[super dealloc];
}

-(BOOL)containComments
{
	return mContainComments;
}

-(BOOL)containImages
{
	return mContainImages;
}

-(void)setNilValueForKey:(id)inKey
{
	[self setValue:[NSNumber numberWithInt:0] forKey:inKey];
}

-(int)wordCount
{
	return [mWords count];
}

-(int)wordIndex
{
	return mWordIndex;
}

-(void)setWordIndex:(int)inIndex
{
	mWordIndex = inIndex;
	[mPreview setWord:[mWords objectAtIndex:mWordIndex - 1]];
}

-(BOOL)runModal
{
	[mPreview setDocument:mDocument];
	if ([mWords count] > 0)
		[self setWordIndex:mWordIndex];
	[self formatDidChange:nil];
	NSString *frame = [[NSUserDefaults standardUserDefaults] objectForKey:@"CardControllerWindowFrameV2"];
	if (frame)
		[[self window] setFrame:NSRectFromString(frame) display:NO];
	int returnCode = [NSApp runModalForWindow:[self window]];
	[[self window] orderOut:nil];
	[[NSUserDefaults standardUserDefaults] setObject:NSStringFromRect([[self window] frame]) forKey:@"CardControllerWindowFrameV2"];
	return returnCode == NSOKButton;
}

-(IBAction)confirm:(id)inSender
{
	[NSApp stopModalWithCode:[inSender tag]];
}

-(float)cardWidth
{
	return [[NSUserDefaults standardUserDefaults] floatForKey:ProVocCardWidth];
}

-(void)setCardWidth:(float)inWidth
{
	[[NSUserDefaults standardUserDefaults] setFloat:MAX(40, inWidth) forKey:ProVocCardWidth];
	if ([[NSUserDefaults standardUserDefaults] integerForKey:ProVocCardFormat] == 0)
		[[NSUserDefaults standardUserDefaults] setFloat:inWidth forKey:ProVocCardCustomWidth];
	[mPreview update:nil];
}

-(float)cardHeight
{
	return [[NSUserDefaults standardUserDefaults] floatForKey:ProVocCardHeight];
}

-(void)setCardHeight:(float)inHeight
{
	[[NSUserDefaults standardUserDefaults] setFloat:MAX(40, inHeight) forKey:ProVocCardHeight];
	if ([[NSUserDefaults standardUserDefaults] integerForKey:ProVocCardFormat] == 0)
		[[NSUserDefaults standardUserDefaults] setFloat:inHeight forKey:ProVocCardCustomHeight];
	[mPreview update:nil];
}

-(IBAction)sizeUnitDidChange:(id)inSender
{
	[self willChangeValueForKey:@"cardWidth"];
	[self willChangeValueForKey:@"cardHeight"];
	[self didChangeValueForKey:@"cardWidth"];
	[self didChangeValueForKey:@"cardHeight"];
	
	NSArray *margins = [NSArray arrayWithObjects:@"Left", @"Top", @"Right", @"Bottom", nil];
	NSEnumerator *enumerator = [margins objectEnumerator];
	NSString *margin;
	while (margin = [enumerator nextObject]) {
		NSString *key = [NSString stringWithFormat:@"card%@Margin", margin];
		[self willChangeValueForKey:key];
		[self didChangeValueForKey:key];
	}
}

-(id)valueForUndefinedKey:(NSString *)inKey
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:inKey];
}

-(void)setValue:(id)inValue forUndefinedKey:(NSString *)inKey
{
	[[NSUserDefaults standardUserDefaults] setObject:inValue forKey:inKey];
	[mPreview update:nil];
}

-(IBAction)formatDidChange:(id)inSender
{
	switch ([[NSUserDefaults standardUserDefaults] integerForKey:ProVocCardFormat]) {
		case 0:
			[self setCardWidth:[[NSUserDefaults standardUserDefaults] floatForKey:ProVocCardCustomWidth]];
			[self setCardHeight:[[NSUserDefaults standardUserDefaults] floatForKey:ProVocCardCustomHeight]];
			break;
		case 1: // CR80 Credit Card
			[self setCardWidth:243];
			[self setCardHeight:153];
			break;
		case 2: // CR79 Visit Card
			[self setCardWidth:238];
			[self setCardHeight:145];
			break;
	}
}

@end

@implementation ProVocCardPreview

-(void)setDocument:(ProVocDocument *)inDocument
{
	mDocument = inDocument;
}

-(void)setWord:(ProVocWord *)inWord
{
	mWord = inWord;
	[self update:nil];
}

-(IBAction)update:(id)inSender
{
	[self setNeedsDisplay:YES];
}

-(float)drawCardFrameInRect:(NSRect)inRect cardSize:(NSSize)inCardSize bounds:(NSRect *)outBounds
{
	[NSGraphicsContext saveGraphicsState];
	
	static NSShadow *shadow = nil;
	if (!shadow) {
		shadow = [[NSShadow alloc] init];
		[shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
		[shadow setShadowOffset:NSMakeSize(3, -3)];
		[shadow setShadowBlurRadius:3.0];
	}
	[shadow set];

	float factor = MIN(1.0, MIN(inRect.size.width / inCardSize.width, inRect.size.height / inCardSize.height));
	NSRect rect;
	rect.size.width = round(inCardSize.width * factor);
	rect.size.height = round(inCardSize.height * factor);
	rect.origin.x = round(NSMidX(inRect) - rect.size.width / 2);
	rect.origin.y = round(NSMidY(inRect) - rect.size.height / 2);
	
	NSColor *color = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:ProVocCardBackgroundColor]];
	[color set];
	[NSBezierPath fillRect:rect];
	[NSGraphicsContext restoreGraphicsState];

	[[NSColor blackColor] set];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:ProVocCardDisplayFrames])
		NSFrameRect(rect);
	
	if (outBounds)
		*outBounds = rect;
	return factor;
}

-(void)drawSide:(int)inSide inRect:(NSRect)inRect scale:(float)inScale cardSize:(NSSize)inCardSize
{
	NSString *text = inSide == 0 ? [mWord sourceWord] : [mWord targetWord];
	if ([text length] == 0)
		return;
	NSString *fontFamilyName = inSide == 0 ? [mDocument sourceFontFamilyName] : [mDocument targetFontFamilyName];
	float fontSize = inSide == 0 ? [mDocument sourceFontSize] : [mDocument targetFontSize];
	fontSize = round(fontSize * exp([[NSUserDefaults standardUserDefaults] floatForKey:ProVocCardTextSize]));

	[NSGraphicsContext saveGraphicsState];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:ProVocCardTextColor]] forKey:NSForegroundColorAttributeName];
	NSMutableParagraphStyle *paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[paragraphStyle setAlignment:NSCenterTextAlignment];
	[attributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
	NSFont *font = [NSFont systemFontOfSize:fontSize];
	font = [[NSFontManager sharedFontManager] convertFont:font toFamily:fontFamilyName];
	[attributes setObject:font forKey:NSFontAttributeName];
	NSMutableAttributedString *string = [[[NSMutableAttributedString alloc] initWithString:text attributes:attributes] autorelease];
	
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform translateXBy:NSMidX(inRect) yBy:NSMidY(inRect)];
	[transform scaleBy:inScale];
	[transform concat];
	
	NSRect rect;
	rect.size = inCardSize;
	rect.origin.x = -rect.size.width / 2;
	rect.origin.y = -rect.size.height / 2;
	[ProVocCardsView drawCardString:string withFontFamilyName:fontFamilyName fontSize:fontSize forRecto:inSide == 0 ofWord:mWord ofDocument:mDocument inRect:rect];
	[NSGraphicsContext restoreGraphicsState];
}

-(void)drawRect:(NSRect)inRect
{
	NSSize cardSize = NSMakeSize([[NSUserDefaults standardUserDefaults] floatForKey:ProVocCardWidth],
									[[NSUserDefaults standardUserDefaults] floatForKey:ProVocCardHeight]);
	float scale;
	NSRect leftRect, rightRect;
	
	float previewMargin = 10;
	[[NSColor colorWithCalibratedWhite:0.8 alpha:1.0] set];
	if ([[NSUserDefaults standardUserDefaults] integerForKey:ProVocCardPaperSides] == 2) {
		float margin = 10;
		NSRect marginRect;
		if ([[NSUserDefaults standardUserDefaults] integerForKey:ProVocCardFlipDirection] == 0) {
			NSDivideRect([self bounds], &leftRect, &rightRect, round(([self bounds].size.width - margin) / 2), NSMinXEdge);
			NSDivideRect(rightRect, &marginRect, &rightRect, margin, NSMinXEdge);
		} else {
			NSDivideRect([self bounds], &leftRect, &rightRect, round(([self bounds].size.height - margin) / 2), NSMaxYEdge);
			NSDivideRect(rightRect, &marginRect, &rightRect, margin, NSMaxYEdge);
		}

		NSRectFill(leftRect);
		NSRectFill(rightRect);
		[[NSColor grayColor] set];
		NSFrameRect(leftRect);
		NSFrameRect(rightRect);
		
		scale = [self drawCardFrameInRect:NSInsetRect(leftRect, previewMargin, previewMargin) cardSize:cardSize bounds:&leftRect];
		scale = [self drawCardFrameInRect:NSInsetRect(rightRect, previewMargin, previewMargin) cardSize:cardSize bounds:&rightRect];
	} else {
		NSRectFill([self bounds]);
		[[NSColor grayColor] set];
		NSFrameRect([self bounds]);
		
		NSSize size = cardSize;
		if ([[NSUserDefaults standardUserDefaults] integerForKey:ProVocCardFlipDirection] == 0)
			size.width *= 2;
		else
			size.height *= 2;
		NSRect rect;
		scale = [self drawCardFrameInRect:NSInsetRect([self bounds], previewMargin, previewMargin) cardSize:size bounds:&rect];
		NSBezierPath *path = [NSBezierPath bezierPath];
		if ([[NSUserDefaults standardUserDefaults] integerForKey:ProVocCardFlipDirection] == 0) {
			NSDivideRect(rect, &leftRect, &rightRect, rect.size.width / 2, NSMinXEdge);
			[path moveToPoint:NSMakePoint(floor(NSMidX(rect)) + 0.5, NSMinY(rect))];
			[path relativeLineToPoint:NSMakePoint(0, rect.size.height)];
		} else {
			NSDivideRect(rect, &leftRect, &rightRect, rect.size.height / 2, NSMaxYEdge);
			[path moveToPoint:NSMakePoint(NSMinX(rect), floor(NSMidY(rect)) + 0.5)];
			[path relativeLineToPoint:NSMakePoint(rect.size.width, 0)];
		}
		const float pattern[2] = {4, 4};
		[path setLineDash:pattern count:2 phase:0];
		if ([[NSUserDefaults standardUserDefaults] boolForKey:ProVocCardDisplayFrames])
			[path stroke];
	}
	[self drawSide:0 inRect:leftRect scale:scale cardSize:cardSize];
	[self drawSide:1 inRect:rightRect scale:scale cardSize:cardSize];
}

@end


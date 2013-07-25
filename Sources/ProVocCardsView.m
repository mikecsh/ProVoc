//
//  ProVocCardsView.m
//  ProVoc
//
//  Created by Simon Bovet on 25.04.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import "ProVocCardsView.h"
#import "ProVocWord.h"
#import "ProVocPreferences.h"
#import "ProVocInspector.h"
#import "ProVocTester.h"

#import "StringExtensions.h"
#import "ImageExtensions.h"

@implementation ProVocCardsView

-(void)updatePagination:(NSPrintOperation *)inPrintOperation
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	mPaperSides = [defaults integerForKey:ProVocCardPaperSides];
	mFontSizeFactor = exp([defaults floatForKey:ProVocCardTextSize]);
	mCardSize = NSMakeSize([defaults floatForKey:ProVocCardWidth], [defaults floatForKey:ProVocCardHeight]);
	mFlipVertically = [defaults integerForKey:ProVocCardFlipDirection] == 1;
	if (mPaperSides == 1) {
		if (mFlipVertically)
			mCardSize.height *= 2;
		else
			mCardSize.width *= 2;
	}
	NSPrintInfo *info = [inPrintOperation printInfo];
	mPaperSize = [info paperSize];
	NSRect imageable = [info imageablePageBounds];
	float horizontalMargin = MAX(imageable.origin.x, mPaperSize.width - NSMaxX(imageable));
	float verticalMargin = MAX(imageable.origin.y, mPaperSize.height - NSMaxY(imageable));
	[info setLeftMargin:horizontalMargin];
	[info setRightMargin:horizontalMargin];
	[info setBottomMargin:verticalMargin];
	[info setTopMargin:verticalMargin];
	mPaperBounds.origin.x = [info leftMargin];
	mPaperBounds.origin.y = [info bottomMargin];
	mPaperBounds.size.width = mPaperSize.width - mPaperBounds.origin.x - [info rightMargin];
	mPaperBounds.size.height = mPaperSize.height - mPaperBounds.origin.y - [info topMargin];
	mColumns = floor(mPaperBounds.size.width / mCardSize.width);
	mRows = floor(mPaperBounds.size.height / mCardSize.height);
	mPages = MAX(1, ceil((float)[mWords count] / (mColumns * mRows)));
	[self setFrameSize:NSMakeSize(mPaperSize.width, mPaperSides * mPages * mPaperSize.height)];
}

-(id)initWithDocument:(ProVocDocument *)inDocument words:(NSArray *)inWords
{
	if (self = [super initWithFrame:NSZeroRect]) {
		mDocument = [inDocument retain];
	    mWords = [inWords retain];
	}
	return self;
}

-(void)dealloc
{
	[mDocument release];
	[mWords release];
	[super dealloc];
}

-(BOOL)knowsPageRange:(NSRangePointer)outRange
{
	[self updatePagination:[NSPrintOperation currentOperation]];
    outRange->location = 1;
    outRange->length = mPaperSides * mPages;
    return YES;
}

-(NSRect)rectForPage:(int)inPage
{
	NSRect rect = NSZeroRect;
	rect.origin.y = (inPage - 1) * mPaperSize.height;
	rect.size = mPaperSize;
    return rect;
}

+(NSMutableAttributedString *)adjustString:(NSMutableAttributedString *)inString toSize:(NSSize)inSize
	withFontFamilyName:(NSString *)inFontFamilyName fontSize:(float)inFontSize height:(float *)outHeight
{
	*outHeight = [inString heightForWidth:inSize.width];
	if (*outHeight < inSize.height)
		return inString;
	
	NSMutableAttributedString *string = [[inString mutableCopy] autorelease];
	float fontSize = inFontSize;
	for (;;) {
		fontSize --;
		if (fontSize < 5)
			break;
		NSFont *font = [NSFont systemFontOfSize:fontSize];
		font = [[NSFontManager sharedFontManager] convertFont:font toFamily:inFontFamilyName];
		[string addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [string length])];
		*outHeight = [string heightForWidth:inSize.width];
		if (*outHeight < inSize.height)
			break;
	}
	return string;
}

+(void)drawCardString:(NSMutableAttributedString *)string
		withFontFamilyName:(NSString *)fontFamilyName fontSize:(float)fontSize
		forRecto:(BOOL)inRecto ofWord:(ProVocWord *)inWord ofDocument:(ProVocDocument *)inDocument inRect:(NSRect)rect
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	float maxHorMargin = rect.size.width / 2 - 10;
	float maxVerMargin = rect.size.height / 2 - 10;
	float leftMargin = MIN(maxHorMargin, [defaults floatForKey:@"cardLeftMargin"]);
	float rightMargin = MIN(maxHorMargin, [defaults floatForKey:@"cardRightMargin"]);
	float topMargin = MIN(maxVerMargin, [defaults floatForKey:@"cardTopMargin"]);
	float bottomMargin = MIN(maxVerMargin, [defaults floatForKey:@"cardBottomMargin"]);
	if (!inRecto)
		if ([defaults integerForKey:ProVocCardFlipDirection] == 1) {
			float swap = topMargin;
			topMargin = bottomMargin;
			bottomMargin = swap;
		}
        else
        {
			float swap = leftMargin;
			leftMargin = rightMargin;
			rightMargin = swap;
		}
	rect.origin.x += leftMargin;
	rect.size.width -= leftMargin + rightMargin;
	rect.origin.y += bottomMargin;
	rect.size.height -= bottomMargin + topMargin;
	
	NSRect r = NSInsetRect(rect, 2, 2);
	[NSGraphicsContext saveGraphicsState];
	[NSBezierPath clipRect:r];
	r = NSInsetRect(r, 5, 5);
	if (([defaults integerForKey:ProVocCardDisplayImages] & (inRecto ? 1 : 2)) != 0) {
		NSImage *image = [inDocument imageOfWord:inWord];
		[image drawScaledProportionallyInRect:r fraction:[defaults floatForKey:ProVocCardImageFraction]];
	}
	NSString *tag = nil;
	switch ([defaults integerForKey:ProVocCardTagDisplay]) {
		case 0:
			break;
		case 1:
			tag = [inDocument displayName];
			break;
		case 2:
			tag = [[inWord page] title];
			break;
		case 3:
			tag = [NSString stringWithFormat:@"%@ %C %@", [inDocument displayName], 0x2014, [[inWord page] title]];
			break;
	}
	if (tag) {
		static NSMutableDictionary *attributes = nil;
		if (!attributes) {
			NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
			[paragraphStyle setAlignment:NSRightTextAlignment];
			attributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSFont systemFontOfSize:[NSFont labelFontSize]], NSFontAttributeName,
															paragraphStyle, NSParagraphStyleAttributeName,
															nil];
			[paragraphStyle release];
		}
		NSColor *color = [NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:ProVocCardTextColor]];
		color = [color colorWithAlphaComponent:[defaults floatForKey:ProVocCardTagFraction]];
		attributes[NSForegroundColorAttributeName] = color;
		[tag drawInRect:NSInsetRect(rect, 6, 4) withAttributes:attributes];
		topMargin = [NSFont labelFontSize];
		r.size.height -= topMargin;
	}
	
	NSString *comment = [inWord comment];
	if ([comment length] > 0 && ([defaults integerForKey:ProVocCardDisplayComments] & (inRecto ? 1 : 2)) != 0) {
		static NSMutableDictionary *attributes = nil;
		if (!attributes) {
			NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
			[paragraphStyle setAlignment:NSCenterTextAlignment];
			attributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:paragraphStyle, NSParagraphStyleAttributeName,
															nil];
			[paragraphStyle release];
		}
		NSFont *font = [NSFont fontWithName:[defaults objectForKey:@"commentFontFamilyName"] size:[NSFont labelFontSize] * [defaults floatForKey:ProVocCardCommentSize]];
		attributes[NSFontAttributeName] = font;
		attributes[NSForegroundColorAttributeName] = [NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:ProVocCardTextColor]];
		
		NSAttributedString *string = [[NSAttributedString alloc] initWithString:comment attributes:attributes];
		NSRect bounds = NSInsetRect(rect, 6, 4);
		bottomMargin = [string heightForWidth:bounds.size.width] + 2;
		bounds.origin.y -= bounds.size.height - bottomMargin;
		[string drawInRect:bounds];
		[string release];
		r.origin.y += bottomMargin;
		r.size.height -= bottomMargin;
	}
	
	NSArray *synonyms = [[string string] synonyms];
	if ([synonyms count] > 1)
		[string replaceCharactersInRange:NSMakeRange(0, [string length]) withString:[synonyms componentsJoinedByString:@"\n"]];
	float height;
	string = [self adjustString:string toSize:r.size withFontFamilyName:fontFamilyName fontSize:fontSize height:&height];
	NSRect stringRect = r;
	bottomMargin = 20;
	stringRect.origin.y = NSMidY(r) - height / 2 - bottomMargin + 2;
	stringRect.size.height = height + bottomMargin;
	[string drawInRect:stringRect];
	[NSGraphicsContext restoreGraphicsState];
}

-(void)drawRect:(NSRect)inRect
{
	int columns = mColumns;
	int rows = mRows;
	int page, column, row;
	int card;
	
	[NSBezierPath setDefaultLineWidth:0.2];
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	attributes[NSForegroundColorAttributeName] = [NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:ProVocCardTextColor]];
	NSMutableParagraphStyle *paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[paragraphStyle setAlignment:NSCenterTextAlignment];
	attributes[NSParagraphStyleAttributeName] = paragraphStyle;
	float sourceFontSize = mFontSizeFactor * [defaults floatForKey:@"sourceFontSize"];
	NSFont *font = [NSFont systemFontOfSize:sourceFontSize];
	NSString *sourceFontFamilyName = [defaults objectForKey:@"sourceFontFamilyName"];
	font = [[NSFontManager sharedFontManager] convertFont:font toFamily:sourceFontFamilyName];
	attributes[NSFontAttributeName] = font;
	NSMutableAttributedString *sourceString = [[[NSMutableAttributedString alloc] initWithString:@"dummy" attributes:attributes] autorelease];
	float targetFontSize = mFontSizeFactor * [defaults floatForKey:@"targetFontSize"];
	font = [NSFont systemFontOfSize:targetFontSize];
	NSString *targetFontFamilyName = [defaults objectForKey:@"targetFontFamilyName"];
	font = [[NSFontManager sharedFontManager] convertFont:font toFamily:targetFontFamilyName];
	attributes[NSFontAttributeName] = font;
	NSMutableAttributedString *targetString = [[[NSMutableAttributedString alloc] initWithString:@"dummy" attributes:attributes] autorelease];
	
	NSColor *backGroundColor = [NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:ProVocCardBackgroundColor]];
	BOOL drawFrames = [defaults boolForKey:ProVocCardDisplayFrames];
	
	BOOL flip = mPaperSides == 2 && mFlipVertically;
	for (page = 1; page <= mPaperSides * mPages; page++) {
		BOOL recto = mPaperSides == 1 || page % 2 == 1;
		NSRect pageRect = [self rectForPage:page];
		if (NSIntersectsRect(pageRect, inRect)) {
			NSAffineTransform *transform = nil;
			if (!recto && flip && mPaperSides == 2) {
				[NSGraphicsContext saveGraphicsState];
				transform = [NSAffineTransform transform];
				[transform translateXBy:NSMidX(pageRect) yBy:NSMidY(pageRect)];
				[transform scaleBy:-1];
				[transform translateXBy:-NSMidX(pageRect) yBy:-NSMidY(pageRect)];
				[transform concat];
			}
			
			NSRect cardRect = pageRect;
			cardRect.size = mCardSize;
			for (column = 0; column < columns; column++) {
				if (recto || flip || mPaperSides == 1)
					cardRect.origin.x = mPaperBounds.origin.x + column * mCardSize.width;
				else
					cardRect.origin.x = NSMaxX(mPaperBounds) - (column + 1) * mCardSize.width;
				for (row = 0; row < rows; row++) {
					card = (page - 1) / mPaperSides * columns * rows + row * columns + column;
					if (card < [mWords count]) {
						if ((!recto || !flip) && mPaperSides == 2)
							cardRect.origin.y = NSMaxY(mPaperBounds) - (rows - row) * mCardSize.height;
						else
							cardRect.origin.y = mPaperBounds.origin.y + (rows - row - 1) * mCardSize.height;
						cardRect.origin.y += pageRect.origin.y;
						[backGroundColor set];
						NSRectFill(cardRect);
						if (recto && drawFrames) {
							[[NSColor blackColor] set];
							[NSBezierPath strokeRect:cardRect];
						}
						ProVocWord *word = mWords[card];
						if (mPaperSides == 2) {
							NSMutableAttributedString *string = recto ? sourceString : targetString;
							NSString *fontFamilyName = recto ? sourceFontFamilyName : targetFontFamilyName;
							float fontSize = recto ? sourceFontSize : targetFontSize;
							[string replaceCharactersInRange:NSMakeRange(0, [string length]) withString:recto ? [word sourceWord] : [word targetWord]];
							[[self class] drawCardString:string withFontFamilyName:fontFamilyName fontSize:fontSize forRecto:recto ofWord:word ofDocument:mDocument inRect:cardRect];
						} else {
							for (recto = 0; recto < 2; recto++) {
								NSMutableAttributedString *string = recto ? sourceString : targetString;
								NSString *fontFamilyName = recto ? sourceFontFamilyName : targetFontFamilyName;
								float fontSize = recto ? sourceFontSize : targetFontSize;
								[string replaceCharactersInRange:NSMakeRange(0, [string length]) withString:recto ? [word sourceWord] : [word targetWord]];
								NSRect rect = cardRect;
								if (mFlipVertically) {
									rect.size.height /= 2;
									if (recto)
										rect.origin.y += rect.size.height;
								} else {
									rect.size.width /= 2;
									if (!recto)
										rect.origin.x += rect.size.width;
								}
								[[self class] drawCardString:string withFontFamilyName:fontFamilyName fontSize:fontSize forRecto:recto ofWord:word ofDocument:mDocument inRect:rect];
								
								if (recto && drawFrames) {
									NSBezierPath *path = [NSBezierPath bezierPath];
									if (!mFlipVertically) {
										[path moveToPoint:NSMakePoint(NSMidX(cardRect), NSMinY(cardRect))];
										[path relativeLineToPoint:NSMakePoint(0, cardRect.size.height)];
									} else {
										[path moveToPoint:NSMakePoint(NSMinX(cardRect), NSMidY(cardRect))];
										[path relativeLineToPoint:NSMakePoint(cardRect.size.width, 0)];
									}
									const float pattern[2] = {4, 4};
									[path setLineDash:pattern count:2 phase:0];
									[path stroke];
								}
							}
						}
					}
				}
			}
			if (!recto && flip)
				[NSGraphicsContext restoreGraphicsState];
		}
	}
}

@end

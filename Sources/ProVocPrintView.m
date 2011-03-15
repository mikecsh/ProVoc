//
//  ProVocPrintView.m
//  ProVoc
//
//  Created by Simon Bovet on 12.10.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import "ProVocPrintView.h"

#import "ProVocDocument+Lists.h"
#import "ProVocWord.h"
#import "StringExtensions.h"
#import "ProVocCardsView.h"

@implementation ProVocPrintView

-(id)initWithDocument:(ProVocDocument *)inDocument
{
	if (self = [super initWithFrame:NSMakeRect(0, 0, 100, 100)]) {
		mDocument = [inDocument retain];
		mProVocPages = [[mDocument selectedPages] retain];
		mPages = [[NSMutableArray alloc] initWithCapacity:0];
	}
	return self;
}

-(void)dealloc
{
	[mDocument release];
	[mProVocPages release];
	[mPages release];
	[mPageTitle release];
	[super dealloc];
}

-(BOOL)isFlipped
{
	return YES;
}

-(float)interWordMargin
{
	return 4;
}

-(float)interColumnMargin
{
	return 10;
}

-(int)numberOfColumns
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:ProVocPrintComments] ? 3 : 2;
}

-(float)wordWidth
{
	int cols = [self numberOfColumns];
	return (mPaperSize.width - (cols - 1) * [self interColumnMargin]) / cols;
}

-(NSDictionary *)stringAttributesForColumn:(int)inColumn
{
	NSString *key = @"sourceFontFamilyName";
	if (inColumn == 1)
		key = @"targetFontFamilyName";
	if (inColumn == 2)
		key = @"commentFontFamilyName";
	NSFont *font = [NSFont systemFontOfSize:[[NSUserDefaults standardUserDefaults] floatForKey:PVPrintListFontSize]];
	font = [[NSFontManager sharedFontManager] convertFont:font toFamily:[[NSUserDefaults standardUserDefaults] objectForKey:key]];
	return [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
}

-(float)heightForString:(NSString *)inString inColumn:(int)inColumn
{
	NSAttributedString *string = [[NSAttributedString alloc] initWithString:inString attributes:[self stringAttributesForColumn:inColumn]];
	float height = [string heightForWidth:[self wordWidth]];
	[string release];
	return height;
}

-(float)heightForWord:(ProVocWord *)inWord
{
	float height = MAX([self heightForString:[inWord sourceWord] inColumn:0], [self heightForString:[inWord targetWord] inColumn:1]);
	if ([self numberOfColumns] >= 3)
		height = MAX(height, [self heightForString:[inWord comment] inColumn:2]);
	return height;
}

-(void)closePage
{
	float height = mCurrentY - mCurrentPageTop;
	mCurrentY += mPaperSize.height - height;
	[mCurrentPage setObject:[NSNumber numberWithFloat:mCurrentY] forKey:@"Bottom"];
}

-(void)newPage
{
	[self closePage];
	mCurrentPageTop = mCurrentY;
	mCurrentWords = [[NSMutableArray alloc] init];
	mCurrentPage = [[NSMutableDictionary alloc] initWithObjectsAndKeys:mPageTitle, @"Title",
												[NSNumber numberWithFloat:mCurrentPageTop], @"Top",
												mCurrentWords, @"Words",
												nil];
	[mCurrentWords release];
	[mPages addObject:mCurrentPage];
	[mCurrentPage release];
}

-(float)titleTopMargin
{
	return 24.0;
}

-(float)titleBottomMargin
{
	return 14.0;
}

-(void)addPageSeparator:(ProVocPage *)inPage
{
	NSMutableArray *words = [[[inPage words] mutableCopy] autorelease];
	[mDocument sortWords:words];
	if ([words count] == 0)
		return;
	ProVocWord *word = [words objectAtIndex:0];
	float nextWordHeight = [self heightForWord:word];

	NSAttributedString *string = [[NSAttributedString alloc] initWithString:mPageTitle attributes:[self stringAttributesForColumn:1]];
	float textHeight = [string heightForWidth:mPaperSize.width];
	[string release];
	float height = textHeight + [self titleTopMargin] + [self titleBottomMargin];
	if (mCurrentY != mCurrentPageTop && mCurrentY + height + nextWordHeight - mCurrentPageTop > mPaperSize.height) {
		[self newPage];
		return;
	}
	[mCurrentWords addObject:[NSDictionary dictionaryWithObjectsAndKeys:mPageTitle, @"Page Seperator",
															[NSNumber numberWithFloat:mCurrentY + [self titleTopMargin]], @"Top",
															[NSNumber numberWithFloat:textHeight], @"Height",
															nil]];
	mCurrentY += height + [self interWordMargin];
}

-(void)addWord:(ProVocWord *)inWord
{
	float height = [self heightForWord:inWord];
	if (mCurrentY != mCurrentPageTop && mCurrentY + height - mCurrentPageTop > mPaperSize.height)
		[self newPage];
	[mCurrentWords addObject:[NSDictionary dictionaryWithObjectsAndKeys:inWord, @"Word",
															[NSNumber numberWithFloat:mCurrentY], @"Top",
															[NSNumber numberWithFloat:height], @"Height",
															nil]];
	mCurrentY += height + [self interWordMargin];
}

-(void)updatePagination:(NSPrintOperation *)inPrintOperation
{
	NSPrintInfo *info = [inPrintOperation printInfo];
	mPaperSize = [info paperSize];
	mPaperSize.width -= [info leftMargin] + [info rightMargin];
	mPaperSize.height -= [info topMargin] + [info bottomMargin];
	
	[mPages removeAllObjects];
	mCurrentY = 0;
	
	BOOL firstPage = YES;
	BOOL compact = YES;
	NSEnumerator *pageEnumerator = [mProVocPages objectEnumerator];
	ProVocPage *page;
	while (page = [pageEnumerator nextObject]) {
		[mPageTitle release];
		mPageTitle = [[page title] retain];
		if (firstPage || !compact)
			[self newPage];
		else
			[self addPageSeparator:page];
		firstPage = NO;
		
		NSMutableArray *words = [[[page words] mutableCopy] autorelease];
		[mDocument sortWords:words];
		NSEnumerator *enumerator = [words objectEnumerator];
		ProVocWord *word;
		while (word = [enumerator nextObject])
			[self addWord:word];
	}
	[self closePage];

	[self setFrameSize:NSMakeSize(mPaperSize.width, mCurrentY)];
}

-(BOOL)knowsPageRange:(NSRangePointer)outRange
{
	[self updatePagination:[NSPrintOperation currentOperation]];
	if (outRange) {
		outRange->location = 1;
		outRange->length = [mPages count];
	}
	return YES;
}

-(NSRect)rectForPage:(int)inPage
{
	NSRect rect = NSZeroRect;
	mCurrentPage = [mPages objectAtIndex:inPage - 1];
	rect.origin.y = [[mCurrentPage objectForKey:@"Top"] floatValue];
	rect.size.width = mPaperSize.width;
	rect.size.height = [[mCurrentPage objectForKey:@"Bottom"] floatValue] - rect.origin.y;
	return rect;
}

-(void)drawRect:(NSRect)inRect
{
	NSEnumerator *pageEnumerator = [mPages objectEnumerator];
	NSDictionary *page;
	while (page = [pageEnumerator nextObject]) {
		NSEnumerator *wordEnumerator = [[page objectForKey:@"Words"] objectEnumerator];
		NSDictionary *word;
		while (word = [wordEnumerator nextObject]) {
			float top = [[word objectForKey:@"Top"] floatValue];
			float height = [[word objectForKey:@"Height"] floatValue];
			if (top + height >= NSMinY(inRect) || top <= NSMaxY(inRect))
				if ([word objectForKey:@"Page Seperator"]) {
					NSRect r = NSMakeRect(0, top, mPaperSize.width, height + [self interWordMargin]);
					NSAttributedString *string = [[NSAttributedString alloc] initWithString:[word objectForKey:@"Page Seperator"] attributes:[self stringAttributesForColumn:1]];
					[string drawInRect:r];
					[string release];
					NSBezierPath *line = [NSBezierPath bezierPath];
					[line moveToPoint:NSMakePoint(NSMinX(r), NSMinY(r) + height + 4)];
					[line relativeLineToPoint:NSMakePoint(r.size.width, 0)];
					[line setLineWidth:0.5];
					[line stroke];
				} else {
					ProVocWord *proVocWord = [word objectForKey:@"Word"];
					NSRect r = NSMakeRect(0, top, [self wordWidth], height + [self interWordMargin]);
					NSAttributedString *string = [[NSAttributedString alloc] initWithString:[proVocWord sourceWord] attributes:[self stringAttributesForColumn:0]];
					[string drawInRect:r];
					[string release];
					
					r.origin.x += r.size.width + [self interColumnMargin];
					string = [[NSAttributedString alloc] initWithString:[proVocWord targetWord] attributes:[self stringAttributesForColumn:1]];
					[string drawInRect:r];
					[string release];
					
					if ([self numberOfColumns] > 2) {
						NSString *comment = [proVocWord comment];
						if (comment) {
							r.origin.x += r.size.width + [self interColumnMargin];
							string = [[NSAttributedString alloc] initWithString:comment attributes:[self stringAttributesForColumn:2]];
							[string drawInRect:r];
							[string release];
						}
					}
				}
		}
	}
}

-(void)drawPageBorderWithSize:(NSSize)inSize
{
	NSRect rect = NSZeroRect;
	rect.size = inSize;
	
	NSPrintInfo *info = [NSPrintInfo sharedPrintInfo];
	rect.origin.x += [info leftMargin];
	rect.origin.y += [info bottomMargin];
	rect.size.width -= [info leftMargin] + [info rightMargin];
	rect.size.height -= [info bottomMargin] + [info topMargin];

	[[mCurrentPage objectForKey:@"Title"] drawAtPoint:NSMakePoint(NSMinX(rect), NSMaxY(rect) + [self titleBottomMargin]) withAttributes:[self stringAttributesForColumn:1]];
	NSBezierPath *line = [NSBezierPath bezierPath];
	[line moveToPoint:NSMakePoint(NSMinX(rect), NSMaxY(rect) + [self titleBottomMargin] - 4)];
	[line relativeLineToPoint:NSMakePoint(rect.size.width, 0)];
	[line setLineWidth:0.5];
	[line stroke];

	if ([[NSUserDefaults standardUserDefaults] boolForKey:ProVocPrintPageNumbers]) {
		NSMutableDictionary *attributes = [[NSMutableDictionary alloc] initWithDictionary:[self stringAttributesForColumn:1]];
		NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[paragraphStyle setAlignment:NSCenterTextAlignment];
		[attributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
		[paragraphStyle release];
		NSAttributedString *string = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Print Page Format %i of %i", @""), [mPages indexOfObjectIdenticalTo:mCurrentPage] + 1, [mPages count]] attributes:attributes];
		[attributes release];
		[string drawInRect:NSMakeRect(rect.origin.x, 0, rect.size.width, NSMinY(rect) - 10)];
		[string release];
	}
}

@end

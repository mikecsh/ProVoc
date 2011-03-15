//
//  ProVocHistoryView.m
//  ProVoc
//
//  Created by Simon Bovet on 25.02.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ProVocHistoryView.h"
#import "StringExtensions.h"
#import "BezierPathExtensions.h"
#import "DateExtensions.h"

@interface ProVocHistory (HistoryView)

+(ProVocHistory *)noHistory;
-(void)drawInRect:(NSRect)inRect total:(int)inTotal;

@end


@implementation ProVocHistoryView

-(id)initWithFrame:(NSRect)inFrame
{
    if (self = [super initWithFrame:inFrame]) {
		mBins = [[NSMutableArray alloc] initWithCapacity:0];
		mDisplay = 1;
    }
    return self;
}

-(void)dealloc
{
	[mBins release];
	[super dealloc];
}

-(int)yTickWithDivisions:(int)inDivisions
{
	float yTick = mTotal / inDivisions;
	float yTickExp = pow(10, ceil(log10(yTick)));
	float yTickBasis = yTick / yTickExp;
	if (yTickBasis < 0.15)
		yTickBasis = 0.1;
	else if (yTickBasis < 0.35)
		yTickBasis = 0.2;
	else if (yTickBasis < 0.75)
		yTickBasis = 0.5;
	else
		yTickBasis = 1.0;
	return MAX(1, yTickBasis * yTickExp);
}

-(void)drawLegend:(NSString *)inLegend withColor:(NSColor *)inColor rect:(NSRect *)ioRect
{
	[NSGraphicsContext saveGraphicsState];
	static NSDictionary *attributes = nil;
	static NSShadow *shadow = nil;
	if (!attributes) {
		attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName,
														[NSColor blackColor], NSForegroundColorAttributeName,
														nil];
		shadow = [[NSShadow alloc] init];
		[shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.25]];
		[shadow setShadowBlurRadius:5.0];
		[shadow setShadowOffset:NSMakeSize(2, -2)];
	}
	[shadow set];
	NSRect symbol;
	NSRect legend;
	float legendWidth = 50;
	NSDivideRect(*ioRect, &symbol, &legend, legendWidth, NSMinXEdge);
	symbol = NSInsetRect(symbol, 6, 4);
	[inColor set];
	[NSBezierPath fillRect:symbol];
	[NSGraphicsContext restoreGraphicsState];
	[[NSColor blackColor] set];
	NSFrameRect(symbol);
	
	legend.size.height += 30;
	legend.origin.y -= 34;
	[inLegend drawInRect:legend withAttributes:attributes];
	float width = [inLegend widthWithAttributes:attributes];
	width = ceil(width + legendWidth + 20);
	ioRect->origin.x += width;
	ioRect->size.width -= width;
}

-(void)drawLegendInRect:(NSRect)inRect
{
	[self drawLegend:NSLocalizedString(@"Correct Legend", @"") withColor:[ProVocHistory colorForRepetition:0] rect:&inRect];
	[self drawLegend:NSLocalizedString(@"Wrong Once Legend", @"") withColor:[ProVocHistory colorForRepetition:1] rect:&inRect];
	[self drawLegend:NSLocalizedString(@"Wrong Twice Legend", @"") withColor:[ProVocHistory colorForRepetition:2] rect:&inRect];
	[self drawLegend:NSLocalizedString(@"Wrong 3+ Legend", @"")withColor:[ProVocHistory colorForRepetition:3] rect:&inRect];
}

-(void)drawHorizontalGridInRect:(NSRect)inRect
{
	int yTick = [self yTickWithDivisions:10];
	NSRect rect = inRect;
	rect.size.height = 1;
	int i;
	for (i = 0; i <= mTotal; i += yTick) {
		[(i == 0 ? [NSColor blackColor] : [NSColor lightGrayColor]) set];
		rect.origin.y = round(inRect.origin.y + i * inRect.size.height / mTotal);
		NSRectFill(rect);
	}
	
	static NSDictionary *attributes = nil;
	if (!attributes) {
		NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[paragraphStyle setAlignment:NSRightTextAlignment];
		attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont systemFontOfSize:0], NSFontAttributeName,
														[NSColor blackColor], NSForegroundColorAttributeName,
														paragraphStyle, NSParagraphStyleAttributeName,
														nil];
		[paragraphStyle release];
	}

	rect.size.width = 50;
	rect.size.height = 50;
	rect.origin.x = inRect.origin.x - rect.size.width - 10;
	yTick = [self yTickWithDivisions:4];
	for (i = 0; i <= mTotal; i += yTick) {
		[(i == 0 ? [NSColor blackColor] : [NSColor lightGrayColor]) set];
		rect.origin.y = round(inRect.origin.y + i * inRect.size.height / mTotal) - rect.size.height + 10;
		NSString *string = [NSString stringWithFormat:@"%i", i];
		[string drawInRect:rect withAttributes:attributes];
	}
}

-(void)drawRect:(NSRect)inRect
{
	[[NSColor whiteColor] set];
	NSRectFill(inRect);
	[[NSColor darkGrayColor] set];
	NSFrameRect([self bounds]);

	NSRect legendFrame;
	NSRect frame;
	NSDivideRect([self bounds], &legendFrame, &frame, 30, NSMaxYEdge);
	[self drawLegendInRect:NSInsetRect(legendFrame, 10, 4)];
	
	frame = NSInsetRect(frame, 50, 100);
	frame.origin.x += 30;
	frame.origin.y += 30;
	[self drawHorizontalGridInRect:frame];

	int i, n = [mBins count];
	
	static NSDictionary *attributes = nil;
	if (!attributes) {
		NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[paragraphStyle setAlignment:NSRightTextAlignment];
		attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName,
														[NSColor blackColor], NSForegroundColorAttributeName,
														paragraphStyle, NSParagraphStyleAttributeName,
														nil];
		[paragraphStyle release];
	}

	NSDate *referenceDate = [(ProVocHistory *)[mBins lastObject] date];
	NSDate *now = [NSDate date];
	NSRect binLabelFrame;
	binLabelFrame.size.width = 150;
	NSRect binFrame = frame;
	binLabelFrame.size.height = binFrame.size.width = round(frame.size.width / n);
	for (i = 0; i < n; i++) {
		binFrame.origin.x = round(frame.origin.x + i * frame.size.width / n);
		NSRect binRect = NSInsetRect(binFrame, 10, 0);
		ProVocHistory *bin = [mBins objectAtIndex:i];
		if (NSIntersectsRect(binRect, inRect))
			[bin drawInRect:binRect total:mTotal];
		
		if (bin != [ProVocHistory noHistory]) {
			NSPoint rotationOrigin;
			rotationOrigin.x = NSMidX(binFrame);
			rotationOrigin.y = NSMinY(binFrame) - 15;
			[NSGraphicsContext saveGraphicsState];
			NSAffineTransform *transform = [NSAffineTransform transform];
			[transform translateXBy:rotationOrigin.x yBy:rotationOrigin.y];
			[transform rotateByDegrees:45];
			[transform translateXBy:-rotationOrigin.x yBy:-rotationOrigin.y];
			[transform concat];
			NSDate *date = [bin date];
			NSString *format = @"";
			int ago = n - 1 - i;
			switch (mDisplay) {
				case 0:
					if ([date isToday])
						format = NSLocalizedString(@"Today Test Label Format", @"");
					else if ([date isYersterday])
						format = NSLocalizedString(@"Yesterday Test Label Format", @"");
					else
						format = [NSString stringWithFormat:NSLocalizedString(@"%i Days Ago Test Label Format", @""), ago];
					break;
				case 1:
					ago += floor(-[referenceDate timeIntervalSinceNow] / (24 * 60 * 60));
					if (ago == 0)
						format = NSLocalizedString(@"Today Day Label Format", @"");
					else if (ago == 1)
						format = NSLocalizedString(@"Yesterday Day Label Format", @"");
					else
						format = [NSString stringWithFormat:NSLocalizedString(@"%i Days Ago Day Label Format", @""), ago];
					break;
				case 2:
					ago += floor(-[referenceDate timeIntervalSinceNow] / (7 * 24 * 60 * 60));
					if (ago == 0)
						format = NSLocalizedString(@"This Week Week Label Format", @"");
					else if (ago == 1)
						format = NSLocalizedString(@"Last Week Week Label Format", @"");
					else
						format = [NSString stringWithFormat:NSLocalizedString(@"%i Weeks Ago Week Label Format", @""), ago];
					break;
				case 3:
					ago += ([now year] * 12 + [now month]) - ([referenceDate year] * 12 + [referenceDate month]);
					if (ago == 0)
						format = NSLocalizedString(@"This Month Month Label Format", @"");
					else if (ago == 1)
						format = NSLocalizedString(@"Last Month Month Label Format", @"");
					else
						format = [NSString stringWithFormat:NSLocalizedString(@"%i Months Ago Month Label Format", @""), ago];
					break;
			}
			NSString *label = [date descriptionWithCalendarFormat:format timeZone:nil locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
			binLabelFrame.size.height = [label heightForWidth:binLabelFrame.size.width withAttributes:attributes];
			binLabelFrame.origin.x = rotationOrigin.x - binLabelFrame.size.width;
			binLabelFrame.origin.y = rotationOrigin.y - binLabelFrame.size.height / 2;
			binLabelFrame.size.height += 5;
			binLabelFrame.origin.y -= 5;
			[label drawInRect:binLabelFrame withAttributes:attributes];
			[NSGraphicsContext restoreGraphicsState];
		}
	}
}

-(int)display
{
	return mDisplay;
}

-(void)setDisplay:(int)inDisplay
{
	if (mDisplay != inDisplay) {
		[self willChangeValueForKey:@"display"];
		mDisplay = inDisplay;
		[self didChangeValueForKey:@"display"];
		[self reloadData];
	}
}

-(void)updateNumberOfBins
{
	if (mDisplay > 0) {
		int n = [mDataSource numberOfHistories];
		NSDate *lastDate = n == 0 ? [NSDate date] : [[mDataSource historyAtIndex:n - 1] date];
		switch (mDisplay) {
			case 1:
				mReferenceDate = [lastDate beginningOfDay];
				break;
			case 2:
				mReferenceDate = [lastDate beginningOfWeek];
				break;
			case 3:
				mReferenceDate = [lastDate beginningOfMonth];
				break;
		}
		mHistoryIndex = n - 1;
	}
	mNumberOfBins = mDisplay == 2 ? 11 : 12;
}

-(ProVocHistory *)binAtIndex:(int)inIndex
{
	if (mDisplay == 0) {
		int index = [mDataSource numberOfHistories] - mNumberOfBins + inIndex;
		if (index >= 0)
			return [mDataSource historyAtIndex:index];
		else
			return [ProVocHistory noHistory];
	} else {
		ProVocHistory *bin = [[[ProVocHistory alloc] init] autorelease];
		[bin setDate:mReferenceDate];
		while (mHistoryIndex >= 0) {
			ProVocHistory *history = [mDataSource historyAtIndex:mHistoryIndex];
			if ([[history date] compare:mReferenceDate] == NSOrderedAscending)
				break;
			[bin addHistory:history];
			mHistoryIndex--;
		}
		switch (mDisplay) {
			case 1:
				mReferenceDate = [mReferenceDate previousDay];
				break;
			case 2:
				mReferenceDate = [mReferenceDate previousWeek];
				break;
			case 3:
				mReferenceDate = [mReferenceDate previousMonth];
				break;
		}
		return bin;
	}
}

-(void)reloadData
{
	[mBins removeAllObjects];
	[self updateNumberOfBins];
	mTotal = 10;
	int i;
	for (i = mNumberOfBins - 1; i >= 0; i--) {
		ProVocHistory *bin = [self binAtIndex:i];
		mTotal = MAX(mTotal, [bin total]);
		[mBins insertObject:bin atIndex:0];
	}
	
	[self setNeedsDisplay:YES];
}

@end

@implementation ProVocHistory (HistoryView)

+(ProVocHistory *)noHistory
{
	static ProVocHistory *noHistory = nil;
	if (!noHistory)
		noHistory = [[ProVocHistory alloc] init];
	return noHistory;
}

-(void)drawInRect:(NSRect)inRect total:(int)inTotal
{
	int total = [self total];
	if (total == 0)
		return;
	NSRect rect = NSInsetRect(inRect, 1, 1);
	rect.size.height = round(inRect.origin.y + inRect.size.height * total / inTotal) - rect.origin.y;
	[NSGraphicsContext saveGraphicsState];
	static NSShadow *shadow = nil;
	if (!shadow) {
		shadow = [[NSShadow alloc] init];
		[shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
		[shadow setShadowBlurRadius:10.0];
		[shadow setShadowOffset:NSMakeSize(4, -4)];
	}
	[shadow set];
	[[NSColor blackColor] set];
	[[NSBezierPath bezierPathWithRect:NSInsetRect(rect, -1, -1)] fill];
	[NSGraphicsContext restoreGraphicsState];
	int from = 0;
	rect.size.height = 0;
	int i, n = [mRepetitions count];
	for (i = 0; i < n; i++) {
		int count = [[mRepetitions objectAtIndex:i] intValue];
		if (count > 0) {
			from += count;
			rect.origin.y = NSMaxY(rect);
			rect.size.height = round(inRect.origin.y + inRect.size.height * from / inTotal) - rect.origin.y;
			[[[self class] colorForRepetition:i] set];
			[[NSBezierPath bezierPathWithRect:rect] fill];
		}
	}
}

@end


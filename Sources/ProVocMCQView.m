//
//  ProVocMCQView.m
//  ProVoc
//
//  Created by Simon Bovet on 06.10.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import "ProVocMCQView.h"

#import "StringExtensions.h"
#import "BezierPathExtensions.h"
#import "MenuExtensions.h"
#import "SpeechSynthesizerExtensions.h"

#import <QTKit/QTKit.h>

@interface NSObject (MCQViewDelegate)

-(NSString *)answerFontFamilyName;
-(float)answerFontSize;
-(NSWritingDirection)answerWritingDirection;

@end

@implementation ProVocMCQView

-(id)initWithFrame:(NSRect)inFrame
{
	if (self = [super initWithFrame:inFrame]) {
		mColumns = 1;
		mCurrentSoundIndex = -1;
	}
	return self;
}

-(void)dealloc
{
	[mAnswers release];
	[mSounds release];
	[mImages release];
	[mMovies release];
	[mCurrentSound release];
	[super dealloc];
}

-(NSString *)fontFamilyName
{
	return [mDelegate answerFontFamilyName];
}

-(float)fontSize
{
	return [mDelegate answerFontSize];
}

-(NSTextAlignment)textAlignment
{
	int alignment = NSLeftTextAlignment;
	if ([mDelegate answerWritingDirection] == NSWritingDirectionRightToLeft)
		alignment = NSRightTextAlignment;
	return alignment;
}

static QTMovieView *sMovieView = nil;

-(void)stopMovie
{
	[sMovieView pause:nil];
	[sMovieView removeFromSuperview];
}

-(void)playMovie:(id)inSender
{
	if ([sMovieView superview])
		[sMovieView play:nil];
}

-(void)startMovie:(id)inMovie inFrame:(NSRect)inFrame
{
	if (inMovie) {
		[sMovieView pause:nil];
		if (!sMovieView) {
			sMovieView = [[QTMovieView alloc] initWithFrame:NSMakeRect(0, 0, 200, 200)];
			[sMovieView setPreservesAspectRatio:YES];
			[sMovieView setFillColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.0]];
			[sMovieView setControllerVisible:NO];
		}
		[sMovieView setMovie:inMovie];
		[sMovieView setFrame:inFrame];
		[self addSubview:sMovieView];
		[self performSelector:@selector(playMovie:) withObject:nil afterDelay:0.0 inModes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSModalPanelRunLoopMode, NSEventTrackingRunLoopMode, nil]];
	} else
		[self stopMovie];
}

-(NSRect)rectForChoiceAtIndex:(int)inIndex
{
	NSRect rect = [self bounds];
	rect.size.width /= mColumns;
	rect.size.height /= mRows;
	float col = inIndex % mColumns;
	int row = inIndex / mColumns;
	if (row == [mAnswers count] / mColumns)
		col += (mColumns - [mAnswers count] % mColumns) * 0.5;
	rect.origin.x = round(rect.origin.x + col * rect.size.width);
	rect.origin.y = round(rect.origin.y + row * rect.size.height);
	rect.size.width = round(rect.size.width);
	rect.size.height = round(rect.size.height);
	return rect;
}

-(NSRect)contentRectForChoiceAtIndex:(int)inIndex
{
	NSRect rect = [self rectForChoiceAtIndex:inIndex];
	if ([mSounds count] > 0)
		rect.size.width -= 42;
	return rect;
}

-(NSRect)rectForSpeakerIconAtIndex:(int)inIndex
{
	NSRect rect = [self rectForChoiceAtIndex:inIndex];
	rect.origin.x = NSMaxX(rect) - 32 - 5;
	rect.origin.y = NSMidY(rect) - 16;
	rect.size.width = rect.size.height = 32;
	return rect;
}

-(void)drawSpeakerIconAtIndex:(int)inIndex playing:(BOOL)inPlaying
{
	NSImage *image = [NSImage imageNamed:inPlaying ? @"SpeakerOn" : @"SpeakerOff"];
	NSRect rect = [self rectForSpeakerIconAtIndex:inIndex];
	[image dissolveToPoint:NSMakePoint(NSMinX(rect), NSMaxY(rect)) fraction:1.0];
}

-(void)drawString:(NSString *)inString atIndex:(int)inIndex
{
	NSSound *sound = [mSounds objectForKey:[NSNumber numberWithInt:inIndex]];
	if (sound)
		[self drawSpeakerIconAtIndex:inIndex playing:inIndex == mCurrentSoundIndex];
		
	NSRect inRect = [self contentRectForChoiceAtIndex:inIndex];
	
	NSImage *image = [mImages objectForKey:[NSNumber numberWithInt:inIndex]];
	if (image) {
		NSRect src = NSZeroRect;
		src.size = [image size];
		NSRect dst = NSInsetRect(inRect, 8, 8);
		float k = MIN(1, MIN(fabs(dst.size.width / src.size.width), fabs(dst.size.height / src.size.height)));
		dst.size.width = k * src.size.width;
		dst.size.height = k * src.size.height;
		dst.origin.x = NSMidX(inRect) - dst.size.width / 2;
		dst.origin.y = NSMidY(inRect) + dst.size.height / 2;
		[NSGraphicsContext saveGraphicsState];
		NSAffineTransform *transform = [NSAffineTransform transform];
		[transform scaleXBy:1 yBy:-1];
		[transform concat];
		dst.origin.y *= -1;
		[image drawInRect:dst fromRect:src operation:NSCompositeCopy fraction:1.0];
		[NSGraphicsContext restoreGraphicsState];
		return;
	}
	
	if (inString) {
		NSFont *font = [NSFont systemFontOfSize:[self fontSize]];
		font = [[NSFontManager sharedFontManager] convertFont:font toFamily:[self fontFamilyName]];
		NSMutableParagraphStyle *paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
		[paragraphStyle setAlignment:[self textAlignment]];
		NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName,
																	paragraphStyle, NSParagraphStyleAttributeName, nil];
		NSAttributedString *attributedString = [[[NSAttributedString alloc] initWithString:inString attributes:attributes] autorelease];
		NSRect rect = NSInsetRect(inRect, 15, 0);
		rect.size.height = round([attributedString heightForWidth:rect.size.width]);
		rect.origin.y = MAX(NSMinY(inRect), NSMidY(inRect) - round(rect.size.height / 2));
		rect.size.height = inRect.size.height;
		[attributedString drawInRect:rect];
	}
}

-(BOOL)isFlipped
{
	return YES;
}

-(void)drawSelectionType:(int)inType inRect:(NSRect)inRect
{
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundRectInRect:NSInsetRect(inRect, 3, 3) radius:6];
	NSColor *color = inType == 0 ? [NSColor lightGrayColor] : [NSColor redColor];
	[[color blendedColorWithFraction:0.5 ofColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.5]] set];
	[path fill];
	[path setLineWidth:3.0];
	[color set];
	[path stroke];
}

-(void)updateRows
{
	mRows = ceil((float)([mAnswers count]) / mColumns);
}

-(void)startMovieAtIndex:(int)inIndex
{
	[self startMovie:[mMovies objectForKey:[NSNumber numberWithInt:inIndex]] inFrame:NSInsetRect([self contentRectForChoiceAtIndex:inIndex], 8, 8)];
}

-(void)soundStopped
{
	[mCurrentSound release];
	mCurrentSound = nil;
	[self setNeedsDisplayInRect:[self rectForSpeakerIconAtIndex:mCurrentSoundIndex]];
	mCurrentSoundIndex = -1;
}

-(void)stopSound
{
	[mCurrentSound stop];
	[self soundStopped];
}

-(void)playSoundAtIndex:(int)inIndex
{
	[mDelegate stopSound];
	[self stopSound];
	mCurrentSound = [[mSounds objectForKey:[NSNumber numberWithInt:mCurrentSoundIndex = inIndex]] retain];
	[mCurrentSound setDelegate:self];
	[mCurrentSound play];
	[self setNeedsDisplayInRect:[self rectForSpeakerIconAtIndex:mCurrentSoundIndex]];
}

-(void)playSound
{
	if (!mDisplayAnswers)
		return;
	if (mShowSolution)
		[self playSoundAtIndex:mSolutionIndex];
	else if (mSelectedIndex >= 0)
		[self playSoundAtIndex:mSelectedIndex];
}

-(void)playSolutionSound
{
	if (mSelectedIndex != mSolutionIndex)
		[self playSoundAtIndex:mSolutionIndex];
}

-(void)sound:(NSSound *)inSound didFinishPlaying:(BOOL)inFlag
{
	[self soundStopped];
}

-(void)stopMedia
{
	[self stopSound];
	[self stopMovie];
}

-(void)drawRect:(NSRect)inRect
{
	if (!mDisplayAnswers)
		return;
	NSRect rect = [self bounds];
	rect.size.height = floor(rect.size.height / [mAnswers count]);
	NSEnumerator *enumerator = [mAnswers objectEnumerator];
	id answer;
	int index = 0;
	while (answer = [enumerator nextObject]) {
		NSRect rect = [self rectForChoiceAtIndex:index];
		if (index == mSolutionIndex && mShowSolution)
			[self drawSelectionType:1 inRect:rect];
		else if (index == mSelectedIndex)
			[self drawSelectionType:0 inRect:rect];
		NSString *string = [mDelegate stringForAnswer:answer];
		[self drawString:string atIndex:index];
		index++;
	}
}

-(int)indexAtPosition:(NSPoint)inPoint
{
	int i, n = [mAnswers count];
	for (i = 0; i < n; i++)
		if (NSPointInRect(inPoint, [self rectForChoiceAtIndex:i]))
			return i;
	return -1;
}

-(BOOL)canSelectIndex:(int)inIndex
{
	if (!mDelegate)
		return YES;
	else
		return [mDelegate MCQView:self shouldSelectAnswer:[mAnswers objectAtIndex:inIndex]];
}

-(void)selectIndex:(int)inIndex playSound:(BOOL)inPlaySound
{
	BOOL soundPlayed = NO;
	int index = MAX(0, MIN([mAnswers count] - 1, inIndex));
	if (mSelectedIndex != index && [self canSelectIndex:index]) {
		if (mSelectedIndex >= 0)
			[self setNeedsDisplayInRect:[self rectForChoiceAtIndex:mSelectedIndex]];
		mSelectedIndex = index;
		[self startMovieAtIndex:mSelectedIndex];
		[self setNeedsDisplayInRect:[self rectForChoiceAtIndex:mSelectedIndex]];
		if ([mDelegate autoPlaySound]) {
			[self playSoundAtIndex:index];
			soundPlayed = YES;
		}
	}
	if (!soundPlayed && inPlaySound)
		[self playSoundAtIndex:index];
}

-(void)selectIndex:(int)inIndex
{
	[self selectIndex:inIndex playSound:NO];
}

-(void)selectAnswerWithEvent:(NSEvent *)inEvent
{
	NSPoint point = [self convertPoint:[inEvent locationInWindow] fromView:nil];
	int index = [self indexAtPosition:point];
	if (index >= 0)
		[self selectIndex:index playSound:NSPointInRect(point, [self rectForSpeakerIconAtIndex:index])];
}

-(BOOL)acceptsFirstResponder
{
	return YES;
}

-(BOOL)becomeFirstResponder
{
	return YES;
}

-(BOOL)resignFirstResponder
{
	return YES;
}

-(void)moveRow:(int)inDelta
{
	int col = mSelectedIndex % mColumns;
	int row = mSelectedIndex / mColumns;
	row = (row + mRows + inDelta) % mRows;
	[self selectIndex:row * mColumns + col];
}

-(void)moveUp:(id)inSender
{
	if (mSelectedIndex < 0)
		[self selectIndex:[mAnswers count]];
	else
		[self moveRow:-1];
}

-(void)moveLeft:(id)inSender
{
	[self selectIndex:mSelectedIndex < 0 ? [mAnswers count] : mSelectedIndex - 1];
}

-(void)moveDown:(id)inSender
{
	if (mSelectedIndex < 0)
		[self selectIndex:0];
	else
		[self moveRow:1];
}

-(void)moveRight:(id)inSender
{
	[self selectIndex:(mSelectedIndex + 1) % [mAnswers count]];
}

-(id)target
{
	return mTarget;
}

-(void)setTarget:(id)inTarget
{
	mTarget = inTarget;
}

-(SEL)action
{
	return mAction;
}

-(void)setAction:(SEL)inAction
{
	mAction = inAction;
}

-(void)insertNewline:(id)inSender
{
	[self sendAction:[self action] to:[self target]];
}
/*
-(void)doCommandBySelector:(SEL)inSelector
{
	NSLog(@"MCQResponder: %@", NSStringFromSelector(inSelector));
	[super doCommandBySelector:inSelector];
//	if ([self respondsToSelector:inSelector])
//		[self performSelector:inSelector withObject:nil];
}
*/
-(void)insertText:(NSString *)inText
{
	int index = [inText intValue];
	if (index > 0) {
		[self selectIndex:index - 1];
	}
}

-(void)keyDown:(NSEvent *)inEvent
{
	[self interpretKeyEvents:[NSArray arrayWithObject:inEvent]];
}

-(void)mouseDown:(NSEvent *)inEvent
{
	if ([[self window] firstResponder] != self)
		[[self window] makeFirstResponder:self];
	[self selectAnswerWithEvent:inEvent];
	if ([inEvent clickCount] > 1) {
		[self sendAction:[self action] to:[self target]];
		return;
	}
	
	BOOL keepOn = YES;
	while (keepOn) {
		inEvent = [[self window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask];

		switch ([inEvent type]) {
			case NSLeftMouseDragged:
				[self selectAnswerWithEvent:inEvent];
				break;
			case NSLeftMouseUp:
				keepOn = NO;
				break;
			default:
				break;
		}
	}
}

-(int)columns
{
	return mColumns;
}

-(void)setColumns:(int)inColumns
{
	mColumns = inColumns;
	[self updateRows];
}

-(int)rows
{
	return mRows;
}

-(void)setAnswers:(NSArray *)inAnswers solution:(id)inSolution
{
	[mAnswers release];
	mAnswers = [inAnswers retain];
	mSolutionIndex = [mAnswers indexOfObjectIdenticalTo:inSolution];
	mSelectedIndex = -1;
	mShowSolution = NO;
	
	if (!mSounds)
		mSounds = [[NSMutableDictionary alloc] initWithCapacity:0];
	else
		[mSounds removeAllObjects];
	if (!mImages)
		mImages = [[NSMutableDictionary alloc] initWithCapacity:0];
	else
		[mImages removeAllObjects];
	if (!mMovies)
		mMovies = [[NSMutableDictionary alloc] initWithCapacity:0];
	else
		[mMovies removeAllObjects];
	int index = 0;
	NSEnumerator *enumerator = [mAnswers objectEnumerator];
	id answer;
	while (answer = [enumerator nextObject]) {
		id key = [NSNumber numberWithInt:index];
		NSSound *sound = [mDelegate soundForAnswer:answer];
		if (sound)
			[mSounds setObject:sound forKey:key];
		id movie = [mDelegate movieForAnswer:answer];
		if (movie)
			[mMovies setObject:movie forKey:key];
		NSImage *image = [movie posterImage];
		if (!image)
			image = [mDelegate imageForAnswer:answer];
		if (image)
			[mImages setObject:image forKey:key];
		index++;
	}
		
	[self updateRows];
	[self setNeedsDisplay:YES];
}

-(void)showSolution:(id)inSender
{
	mShowSolution = YES;
	[self startMovieAtIndex:mSolutionIndex];
	[self setNeedsDisplayInRect:[self rectForChoiceAtIndex:mSolutionIndex]];
}

-(void)setDisplayAnswers:(BOOL)inDisplay
{
	mDisplayAnswers = inDisplay;
	[self setNeedsDisplay:YES];
}

-(BOOL)isAnswerCorrect
{
	return mSelectedIndex == mSolutionIndex;
}

-(NSString *)selectedAnswer
{
	if (mSelectedIndex >= 0 && mSelectedIndex < [mAnswers count])
		return [mAnswers objectAtIndex:mSelectedIndex];
	else
		return nil;
}

-(float)preferredHeightForNumberOfAnswers:(int)inNumber
{
	return MIN(450, inNumber * 49.0);
}

-(void)setLabel:(id)inSender
{
	[mDelegate setLabel:inSender];
}

@end

@implementation ProVocMCQView (Speech)

static int sIndexToSpeak = -1;

-(NSMenu *)menuForEvent:(NSEvent *)inEvent
{
	NSPoint point = [self convertPoint:[inEvent locationInWindow] fromView:nil];
	sIndexToSpeak = [self indexAtPosition:point];
	
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	[menu addItemWithTitle:NSLocalizedString(@"Start Speaking", @"") target:self selector:@selector(startSpeaking:)];
	[menu addItemWithTitle:NSLocalizedString(@"Stop Speaking", @"") target:self selector:@selector(stopSpeaking:)];
	return menu;
}

-(NSSpeechSynthesizer *)speechSynthesizer
{
	return [NSSpeechSynthesizer commonSpeechSynthesizer];
}

-(void)startSpeaking:(id)inSender
{
	int index = sIndexToSpeak >= 0 ? sIndexToSpeak : mSelectedIndex;
	sIndexToSpeak = -1;
	NSString *string;
	if (index >= 0)
		string = [mAnswers objectAtIndex:index];
	else
		string = [mAnswers componentsJoinedByString:@", "];
	[[self speechSynthesizer] stopSpeaking]; // ++++ v4.2.2 ++++
	[[self speechSynthesizer] startSpeakingString:string];
}

-(BOOL)validateMenuItem:(NSMenuItem *)inItem
{
	SEL selector = [inItem action];
	if (selector == @selector(stopSpeaking:))
		return [[self speechSynthesizer] isSpeaking];
	else
		return [self respondsToSelector:selector];
}

-(void)stopSpeaking:(id)inSender
{
	[[self speechSynthesizer] stopSpeaking];
}

@end

@implementation NSObject (ProVocMCQViewDelegate)

-(BOOL)MCQView:(ProVocMCQView *)inView shouldSelectAnswer:(id)inAnswer
{
	return YES;
}

-(NSString *)stringForAnswer:(id)inAnswer
{
	return nil;
}

-(NSSound *)soundForAnswer:(id)inAnswer
{
	return nil;
}

-(BOOL)autoPlaySound
{
	return NO;
}

-(NSImage *)imageForAnswer:(id)inAnswer
{
	return nil;
}

-(id)movieForAnswer:(id)inAnswer
{
	return nil;
}

@end

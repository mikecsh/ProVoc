//
//  ProVocDocument+Slideshow.m
//  ProVoc
//
//  Created by Simon Bovet on 06.04.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ProVocDocument+Slideshow.h"
#import "ProVocTester.h"
#import "StringExtensions.h"
#import "ArrayExtensions.h"
#import "ProVocTester.h"
#import "ProVocInspector.h"
#import "ProVocSlideshowControlView.h"

#define CANCEL -10
#define STOP -11
static int sSlideNumber;
static BOOL sSkipSlide;
static BOOL sPlayPause;

@interface NSWindow (Extern)

-(void)animateAlphaValueFrom:(float)inFrom to:(float)inTo during:(NSTimeInterval)inInterval;

@end

@interface SlideShowSoundGenerator : NSObject {
	NSMutableArray *mSoundsToPlay;
	NSSound *mCurrentSound;
}

+(SlideShowSoundGenerator *)sharedGenerator;
-(void)playSounds:(NSArray *)inSounds;
-(BOOL)isPlaying;
-(void)stopAllSounds;

@end

@interface SlideView : NSView {
	int mNumberOfRegions;
	NSMutableArray *mAttributedStrings;
	NSImage *mImage;
	NSArray *mSounds;
	id mMovie;
	int mFirstIndex;
	BOOL mSwapFonts;
}

-(id)initWithFrame:(NSRect)inFrame strings:(NSArray *)inStrings swapFonts:(BOOL)inSwapFonts
	image:(NSImage *)inImage movie:(id)inMovie
	sourceSound:(NSSound *)inSourceSound targetSound:(NSSound *)inTargetSound
	firstIndex:(int)inIndex;
-(NSRect)fullRectForWordAtIndex:(int)inIndex;
-(void)displayNow;

@end

@implementation SlideShowSoundGenerator

+(SlideShowSoundGenerator *)sharedGenerator
{
	static SlideShowSoundGenerator *sharedGenerator = nil;
	if (!sharedGenerator)
		sharedGenerator = [[SlideShowSoundGenerator alloc] init];
	return sharedGenerator;
}

-(id)init
{
	if (self = [super init]) {
		mSoundsToPlay = [[NSMutableArray alloc] initWithCapacity:0];
	}
	return self;
}

-(void)playNextSound
{
	if ([mSoundsToPlay count] > 0) {
		mCurrentSound = [mSoundsToPlay[0] retain];
		[mSoundsToPlay removeObjectAtIndex:0];
		[mCurrentSound setDelegate:self];
		[mCurrentSound play];
	}
}

-(void)playSounds:(NSArray *)inSounds
{
	if ([inSounds count] > 0) {
		[self stopAllSounds];
		[mSoundsToPlay setArray:inSounds];
		[self playNextSound];
	}
}

-(BOOL)isPlaying
{
	return [mCurrentSound isPlaying];
}

-(void)stopAllSounds
{
	[mCurrentSound stop];
	[mCurrentSound release];
	mCurrentSound = nil;
	[mSoundsToPlay removeAllObjects];
}

-(void)sound:(NSSound *)inSound didFinishPlaying:(BOOL)inBool
{
	[mCurrentSound release];
	mCurrentSound = nil;
	[self playNextSound];
}

@end

@implementation SlideView

-(NSRect)fullRectForRegionAtIndex:(int)inIndex
{
	const float imageReduction = 0.75;
	NSRect rect = [self bounds];
	rect.size.height = round(rect.size.height / mNumberOfRegions);
	if (mImage)
		rect.size.height = round(rect.size.height * imageReduction);
	rect.origin.y += (mNumberOfRegions - inIndex - 1) * rect.size.height;
	if (mImage && inIndex == 0)
		rect.size.height = round(rect.size.height / imageReduction * (1.0 + (mNumberOfRegions - 1) * (1.0 - imageReduction)));
	return rect;
}

-(NSRect)rectForRegionAtIndex:(int)inIndex
{
	return NSInsetRect([self fullRectForRegionAtIndex:inIndex], 10, 50);
}

-(NSRect)rectForImage
{
	if (!mImage)
		return NSZeroRect;
	NSRect bounds = [self rectForRegionAtIndex:0];
	if (mMovie)
		bounds.size.width /= 2;
	NSRect rect = bounds;
	NSSize size = [mImage size];
	rect.size.width = round(rect.size.height / size.height * size.width);
	if (rect.size.width > size.width) {
		rect.size.width = size.width;
		rect.origin.y += round((rect.size.height - size.height) / 2);
		rect.size.height = size.height;
	}
	rect.origin.x = round(NSMidX(bounds) - rect.size.width / 2);
	return rect;
}

-(NSRect)rectForMovie
{
	NSRect bounds = [self rectForRegionAtIndex:0];
	if (mImage) {
		bounds.size.width /= 2;
		bounds.origin.x += bounds.size.width;
	}
	NSRect rect = bounds;
	NSSize size = [mMovie imageSize];
	float k = MIN(320 / size.width, 240 / size.height);
	if (k > 1.0) {
		size.width *= k;
		size.height *= k;
	}
	rect.size.width = round(rect.size.height / size.height * size.width);
	if (rect.size.width > size.width) {
		rect.size.width = size.width;
		rect.origin.y += round((rect.size.height - size.height) / 2);
		rect.size.height = size.height;
	}
	rect.origin.x = round(NSMidX(bounds) - rect.size.width / 2);
	return rect;
}

-(NSRect)fullRectForWordAtIndex:(int)inIndex
{
	if (mImage || mMovie)
		inIndex++;
	return [self fullRectForRegionAtIndex:inIndex];
}

-(NSRect)rectForWordAtIndex:(int)inIndex
{
	if (mImage || mMovie)
		inIndex++;
	return [self rectForRegionAtIndex:inIndex];
}

-(NSFont *)fontOfSize:(float)inSize forIndex:(int)inIndex
{
	NSFont *font = [NSFont systemFontOfSize:inSize];
	NSString *key = @"sourceFontFamilyName";
	if (inIndex == 1 && !mSwapFonts || inIndex == 0 && mSwapFonts)
		key = @"targetFontFamilyName";
	if (inIndex == 2)
		key = @"commentFontFamilyName";
	font = [[NSFontManager sharedFontManager] convertFont:font toFamily:[[NSUserDefaults standardUserDefaults] objectForKey:key]];
	return font;
}

-(NSShadow *)shadow
{
	static NSShadow *shadow = nil;
	if (!shadow) {
		shadow = [[NSShadow alloc] init];
		[shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
		[shadow setShadowBlurRadius:6];
		[shadow setShadowOffset:NSMakeSize(2, -2)];
	}
	return shadow;
}

-(NSAttributedString *)attributedStringWithString:(NSString *)inString index:(int)inIndex color:(NSColor *)inColor size:(float)inFontSize fittingInSize:(NSSize)inSize
{
	NSMutableParagraphStyle *paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[paragraphStyle setAlignment:NSCenterTextAlignment];
	NSDictionary *attributes = @{NSForegroundColorAttributeName: inColor,
													NSFontAttributeName: [self fontOfSize:inFontSize forIndex:inIndex],
													NSParagraphStyleAttributeName: paragraphStyle,
													NSShadowAttributeName: [self shadow]};
	NSMutableAttributedString *attributedString = [[[NSMutableAttributedString alloc] initWithString:inString attributes:attributes] autorelease];
	while ([attributedString heightForWidth:inSize.width] > inSize.height) {
		if (inFontSize > 20)
			inFontSize -= 10;
		else
			inFontSize--;
		[attributedString addAttribute:NSFontAttributeName value:[self fontOfSize:inFontSize forIndex:inIndex] range:NSMakeRange(0, [attributedString length])];
	}
	return attributedString;
}

static QTMovieView *sMovieView = nil;

-(id)initWithFrame:(NSRect)inFrame strings:(NSArray *)inStrings swapFonts:(BOOL)inSwapFonts
	image:(NSImage *)inImage movie:(id)inMovie
	sourceSound:(NSSound *)inSourceSound targetSound:(NSSound *)inTargetSound
	firstIndex:(int)inIndex
{
	if (self = [super initWithFrame:inFrame]) {
		NSColor *backGroundColor = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:PVTestBackgroundColor]];
		float r, g, b;
		[[backGroundColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&r green:&g blue:&b alpha:nil];
		NSColor *textColor = (r + g + b) / 3 >= 0.5 ? [NSColor blackColor] : [NSColor whiteColor];

		mSwapFonts = inSwapFonts;
		mFirstIndex = inIndex;
		mNumberOfRegions = [inStrings count];
		mImage = [inImage retain];
		mMovie = [inMovie retain];
		if (mImage || mMovie)
			mNumberOfRegions++;
			
		NSMutableArray *sounds = [NSMutableArray array];
		if (inSourceSound)
			[sounds addObject:inSourceSound];
		if (inTargetSound)
			[sounds addObject:inTargetSound];
		mSounds = [sounds copy];
		
		mAttributedStrings = [[NSMutableArray alloc] initWithCapacity:mNumberOfRegions];
		NSEnumerator *enumerator = [inStrings objectEnumerator];
		NSString *string;
		int index = mFirstIndex;
		while (string = [enumerator nextObject]) {
			NSRect wordRect = [self rectForWordAtIndex:index - mFirstIndex];
			float fontSize;
			NSString *key = @"sourceFontSize";
			if (index == 1)
				key = @"targetFontSize";
			if (index == 2)
				key = @"commentFontSize";
			fontSize = MIN(180, MAX(48, 8 * [[NSUserDefaults standardUserDefaults] floatForKey:key]));
			NSAttributedString *attributedString = [self attributedStringWithString:string index:index color:textColor size:fontSize fittingInSize:wordRect.size];
			[mAttributedStrings addObject:attributedString];
			index++;
		}
		
		if (mMovie) {
			if (!sMovieView) {
				sMovieView = [[QTMovieView alloc] initWithFrame:NSMakeRect(0, 0, 200, 200)];
				[sMovieView setPreservesAspectRatio:YES];
				[sMovieView setFillColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.0]];
				[sMovieView setControllerVisible:NO];
			}
			[sMovieView setFrame:[self rectForMovie]];
			[sMovieView setMovie:mMovie];
			[sMovieView performSelector:@selector(play:) withObject:nil afterDelay:0.0 inModes:@[NSDefaultRunLoopMode, NSModalPanelRunLoopMode, NSEventTrackingRunLoopMode]];
			[self addSubview:sMovieView];
		}
	}
	return self;
}

-(void)dealloc
{
	[mAttributedStrings release];
	[mImage release];
	[mMovie release];
	[mSounds release];
	[super dealloc];
}

-(void)drawRect:(NSRect)inRect
{
	if (mImage) {
		NSRect src = NSZeroRect;
		src.size = [mImage size];
		NSRect dst = [self rectForImage];
		[[self shadow] set];
		[NSBezierPath fillRect:dst];
		[mImage drawInRect:dst fromRect:src operation:NSCompositeCopy fraction:1.0];
	}
	if (mMovie) {
		[[self shadow] set];
		[NSBezierPath fillRect:[self rectForMovie]];
	}
	
	NSEnumerator *enumerator = [mAttributedStrings objectEnumerator];
	NSAttributedString *string;
	int index = 0;
	while (string = [enumerator nextObject]) {
		NSRect rect = [self rectForWordAtIndex:index++];
		rect.size.height -= MAX(0, round((rect.size.height - [string heightForWidth:rect.size.width]) / 3));
		rect.origin.y -= 250;
		rect.size.height += 250;
		[string drawInRect:rect];
	}
}

-(void)cancelOperation:(id)inSender
{
	sSlideNumber = CANCEL;
}

-(void)moveLeft:(id)inSender
{
	sSlideNumber -= 2;
}

-(void)insertText:(NSString *)inText
{
	if ([inText isEqual:@" "])
		if (mMovie) {
			sSlideNumber--;
			[sMovieView gotoBeginning:nil];
			[sMovieView play:nil];
		}
        else
        {
			sSlideNumber--;
			sPlayPause = YES;
		}
}

-(void)doCommandBySelector:(SEL)inSelector
{
//	NSLog(@"%@@selector(%@)", NSStringFromSelector(_cmd), NSStringFromSelector(inSelector));
	if ([self respondsToSelector:inSelector])
		[self performSelector:inSelector withObject:nil];
	else {
		if (inSelector == @selector(moveDown:))
			sSkipSlide = YES;
		if (inSelector == @selector(moveUp:) ||
							inSelector == @selector(moveWordBackward:) ||
							inSelector == @selector(moveToBeginningOfLine:) ||
							inSelector == @selector(moveToBeginningOfParagraph:) ||
							inSelector == @selector(moveToBeginningOfDocument:) ||
							inSelector == @selector(pageUp:) ||
							inSelector == @selector(moveBackwardAndModifySelection:) ||
							inSelector == @selector(moveWordBackwardAndModifySelection:) ||
							inSelector == @selector(moveUpAndModifySelection:) ||
							inSelector == @selector(moveWordLeft:) ||
							inSelector == @selector(moveLeftAndModifySelection:) ||
							inSelector == @selector(moveParagraphBackwardAndModifySelection:) ||
							inSelector == @selector(moveWordLeftAndModifySelection:))
			[self moveLeft:nil];
	}
}

-(void)displayNow
{
	[[SlideShowSoundGenerator sharedGenerator] playSounds:mSounds];
	[[self window] animateAlphaValueFrom:0.0 to:1.0 during:0.1];
}

@end

@implementation ProVocDocument (Slideshow)

static NSWindow *sSlide = nil;
static NSWindow *sSecondSlide = nil;
static SlideView *sSlideView = nil;
static SlideView *sSecondSlideView = nil;

-(void)displaySlideWithWord:(ProVocWord *)inWord
{
	NSString *source = [inWord sourceWord] ? [inWord sourceWord] : @"";
	NSString *target = [inWord targetWord] ? [inWord targetWord] : @"";
	NSSound *sourceSound = [self audio:@"Source" ofWord:inWord];
	NSSound *targetSound = [self audio:@"Target" ofWord:inWord];
	BOOL swapped = [self testDirection];
	if (swapped) {
		id swap = source;
		source = target;
		target = swap;
		swap = sourceSound;
		sourceSound = targetSound;
		targetSound = swap;
	}
	BOOL delayTarget = YES;
	BOOL delayComment = delayTarget && YES;
	NSMutableArray *strings = [NSMutableArray arrayWithObjects:source, delayTarget ? @"" : target, nil];
	if ([[inWord comment] length] > 0) {
		[strings addObject:delayComment ? @"" : [inWord comment]];
	} else
		delayComment = NO;
	NSScreen *screen = [NSScreen mainScreen];
	NSRect frame = [screen frame];
	float factor = 1.0;
	if ([NSApp systemVersion] >= 0x1040)
		factor = [screen userSpaceScaleFactor];
	NSRect riFrame = frame;
	riFrame.size.height /= factor;
	riFrame.size.width /= factor;
	sSlide = [[NSWindow alloc] initWithContentRect:riFrame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
	frame.origin = NSZeroPoint;
	sSlideView = [[SlideView alloc] initWithFrame:frame strings:strings swapFonts:swapped
						image:[self imageOfWord:inWord] movie:[self movieOfWord:inWord]
						sourceSound:sourceSound targetSound:delayTarget ? nil : targetSound
						firstIndex:0];
	[sSlide setContentView:sSlideView];
	[sSlide setBackgroundColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.0]];
	[sSlide setOpaque:NO];
	[sSlide setAlphaValue:0.0];
	[sSlide setLevel:NSFloatingWindowLevel + 1];
	[sSlide setHidesOnDeactivate:YES];
	[sSlide orderFront:nil];
	if (delayTarget || delayComment) {
		NSRect frame = [sSlideView fullRectForWordAtIndex:1];
		if (delayComment)
			frame = NSUnionRect(frame, [sSlideView fullRectForWordAtIndex:2]);
		frame = [sSlideView convertRect:frame fromView:nil];
		frame.origin = [sSlide convertBaseToScreen:frame.origin];
		frame.size.height *= factor;
		frame.size.width *= factor;
		sSecondSlide = [[NSWindow alloc] initWithContentRect:frame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
		frame.origin = NSZeroPoint;
		sSecondSlideView = [[SlideView alloc] initWithFrame:frame strings:@[target, delayComment ? [inWord comment] : nil] swapFonts:swapped
									image:nil movie:nil
									sourceSound:nil targetSound:delayTarget ? targetSound : nil
									firstIndex:1];
		[sSecondSlide setContentView:sSecondSlideView];
		[sSecondSlide setBackgroundColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.0]];
		[sSecondSlide setOpaque:NO];
		[sSecondSlide setAlphaValue:0.0];
		[sSecondSlide setLevel:NSFloatingWindowLevel + 1];
		[sSecondSlide setHidesOnDeactivate:YES];
		[sSecondSlide orderFront:nil];
	}
	[sSlideView displayNow];
}

-(void)dimSlide
{
	[[SlideShowSoundGenerator sharedGenerator] stopAllSounds];
	if (sSlideNumber != CANCEL) {
		NSDate *start = [NSDate date];
		float k = 0;
		while (k < 1.0) {
			k = MIN(1.0, -[start timeIntervalSinceNow] / 0.5);
			[sSlide setAlphaValue:1.0 - k];
			if ([sSecondSlide alphaValue] > 0.0)
				[sSecondSlide setAlphaValue:1.0 - k];
		}
		[sSlide setAlphaValue:0.0];
		[sSecondSlide setAlphaValue:0.0];
	}
	[sSlide orderOut:nil];
	[sSecondSlide orderOut:nil];
	[sMovieView pause:nil];
	[sMovieView removeFromSuperview];
	[sSlideView release];
	sSlideView = nil;
	[sSlide setContentView:nil];
	[sSlide release];
	sSlide = nil;
	[sSecondSlideView release];
	sSecondSlideView = nil;
	[sSecondSlide setContentView:nil];
	[sSecondSlide release];
	sSecondSlide = nil;
}

-(BOOL)isMediaPlaying
{
	if ([[SlideShowSoundGenerator sharedGenerator] isPlaying])
		return YES;
	QTMovie *movie = [sMovieView movie];
	if (movie && [movie rate] != 0)
		return YES;
	return NO;
}

-(void)slideshowWithWords:(NSArray *)inWords
{
	if ([inWords count] == 0) {
		NSRunAlertPanel(NSLocalizedString(@"No Word For Slideshow Alert Title", @""), NSLocalizedString(@"No Word For Slideshow Alert Message", @""), nil, nil, nil);
		return;
	}
	
	NSArray *words = [[NSUserDefaults standardUserDefaults] boolForKey:PVSlideshowRandom] ? [inWords shuffledArray] : inWords;
	[NSCursor hide];
	[NSScreen dimScreensHidingMenuBar:YES];

	NSRect controlRect;
	controlRect.size = NSMakeSize(180, 100);
	controlRect.origin.x = NSMidX([[NSScreen mainScreen] frame]) - controlRect.size.width / 2;
	controlRect.origin.y = NSMinY([[NSScreen mainScreen] frame]) + 30;
	NSPanel *controlPanel = [[[NSPanel alloc] initWithContentRect:controlRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES] autorelease];
	controlRect.origin = NSZeroPoint;
	ProVocSlideshowControlView *slideShowControlView = [[[ProVocSlideshowControlView alloc] initWithFrame:controlRect] autorelease];
	[controlPanel setContentView:slideShowControlView];
	[controlPanel setBackgroundColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.0]];
	[controlPanel setOpaque:NO];
	[controlPanel setAlphaValue:0.0];
	[controlPanel setFloatingPanel:YES];
	[controlPanel setLevel:NSFloatingWindowLevel + 2];
	[controlPanel orderFront:nil];

	int n = [words count];
	sSlideNumber = -1;
	while (sSlideNumber >= -1) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		if (sSlideNumber >= 0)
			[self displaySlideWithWord:words[sSlideNumber]];
		int currentSlide = sSlideNumber;
		do {
			BOOL firstSlide = sSecondSlide && [sSecondSlide alphaValue] == 0.0;
			float speed;
rewait:
			speed = [[NSUserDefaults standardUserDefaults] boolForKey:PVSlideshowAutoAdvance] ? (1.0 - [[NSUserDefaults standardUserDefaults] floatForKey:PVSlideshowSpeed]) : 100;
			speed = speed * speed * 8 + 2;
			NSTimeInterval interval = firstSlide ? speed / 3 : speed;
			NSEvent *event;
waitAgain:
			sSkipSlide = NO;
			sPlayPause = NO;
			event = [[self window] nextEventMatchingMask:NSLeftMouseDownMask | NSRightMouseDownMask | NSKeyDownMask
									untilDate:sSlideNumber >= 0 ? [NSDate dateWithTimeIntervalSinceNow:interval] : [NSDate dateWithTimeIntervalSinceNow:0.25]
									inMode:NSDefaultRunLoopMode dequeue:YES];
			if (sSlideNumber >= 0 && !event && [self isMediaPlaying]) {
				interval = 0.2;
				goto waitAgain;
			}
			if ([event type] == NSKeyDown)
				[sSlideView interpretKeyEvents:@[event]];
			if (sPlayPause) {
				[[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:PVSlideshowAutoAdvance] forKey:PVSlideshowAutoAdvance];
				[slideShowControlView highlightControl:[[NSUserDefaults standardUserDefaults] boolForKey:PVSlideshowAutoAdvance] ? @"Play" : @"Pause"];
				goto rewait;
			}
			if (sSlideNumber != CANCEL) {
				if (sSlideNumber == currentSlide && firstSlide && !sSkipSlide)
					[sSecondSlideView displayNow];
				else {
					sSlideNumber = MAX(0, sSlideNumber + 1);
					if (sSlideNumber >= n)
						sSlideNumber = STOP;
				}
			}
		} while (currentSlide == sSlideNumber);
		if (currentSlide >= 0)
			[self dimSlide];
		[pool release];
	}
	[[self window] nextEventMatchingMask:NSLeftMouseDownMask | NSRightMouseDownMask | NSKeyDownMask
									untilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]
									inMode:NSDefaultRunLoopMode dequeue:YES];
	[NSScreen undimScreens];
	[NSCursor unhide];
}

@end

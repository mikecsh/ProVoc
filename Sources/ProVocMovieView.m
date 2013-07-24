//
//  ProVocMovieView.m
//  ProVoc
//
//  Created by Simon Bovet on 16.04.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ProVocMovieView.h"

#import "ProVocImageView.h"

static BOOL sRunningFullscreen = NO;

@implementation ProVocMovieView

-(NSMenu *)menuForEvent:(NSEvent *)inEvent
{
	SEL selector = @selector(fullScreen:);
	NSMenu *menu = [super menuForEvent:inEvent];
	if (sRunningFullscreen) {
		if ([[menu itemAtIndex:0] action] == selector)
			[menu removeItemAtIndex:0];
	} else
		if ([[menu itemAtIndex:0] action] != selector) {
			NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Movie Play Fullscreen Item Title", @"") action:selector keyEquivalent:@""];
			[item setTarget:self];
			[menu insertItem:item atIndex:0];
			[item release];
		}
	return menu;
}

-(BOOL)validateMenuItem:(NSMenuItem *)inItem
{
	if ([inItem action] == @selector(fullScreen:))
		return YES;
	else
		return [super validateMenuItem:inItem];
}

-(float)preferredWidthForHeight:(float)inHeight
{
	float width = 0;
	NSSize imageSize = [[self movie] imageSize];
	if (!NSEqualSizes(imageSize, NSZeroSize))
		width = MIN(imageSize.width, (inHeight - [self controllerBarHeight]) / imageSize.height * imageSize.width);
	return width;
}

-(IBAction)fullScreen:(id)inSender
{
	if (sRunningFullscreen)
		return;
	[self pause:nil];
	[[self movie] displayInFullSize];
}

-(void)mouseDown:(NSEvent *)inEvent
{
	[super mouseDown:inEvent];
	if ([inEvent clickCount] == 3 && NSPointInRect([self convertPoint:[inEvent locationInWindow] fromView:nil], [self bounds]))
		[self fullScreen:nil];
}

-(void)cancelOperation:(id)inSender
{
	if (sRunningFullscreen)
		[NSApp stopModal];
}

-(void)keyDown:(NSEvent *)inEvent
{
	unichar c = [[inEvent characters] characterAtIndex:0];
	if (sRunningFullscreen && c == 27)
		[self cancelOperation:nil];
	else
		[super keyDown:inEvent];
}

-(void)playIfVisible:(id)inSender
{
	if (![self isHidden])
		[self play:inSender];
}

@end

@implementation QTMovie (ProVocMovieView)

-(NSSize)imageSize
{
	NSSize size = NSZeroSize;
	NSValue *sizeValue = [[self movieAttributes] objectForKey:QTMovieNaturalSizeAttribute];
	[sizeValue getValue:&size];
	return size;
}

-(BOOL)windowShouldClose:(id)inSender
{
	if (sRunningFullscreen)
		[NSApp stopModal];
	return YES;
}

-(void)displayInFullSize
{
	NSSize imageSize = [self imageSize];
	if (NSEqualSizes(imageSize, NSZeroSize))
		return;
	NSSize maxSize = [[NSScreen mainScreen] frame].size;
	maxSize.width -= 50;
	maxSize.height -= 50;
	NSRect contentRect = NSZeroRect;
	float k = MIN(1, MIN(maxSize.width / imageSize.width, maxSize.height / imageSize.height));
	contentRect.size.width = MIN(imageSize.width * k, maxSize.width);
	contentRect.size.height = round(contentRect.size.width / imageSize.width * imageSize.height);
	QTMovieView *movieView = [[[[ProVocMovieView class] alloc] initWithFrame:NSZeroRect] autorelease];
	contentRect.size.height += [movieView controllerBarHeight];
	NSWindow *background = [[NSWindow alloc] initWithContentRect:[NSScreen totalFrame] styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
	[background setOpaque:NO];
	[background setBackgroundColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
	[background setLevel:NSModalPanelWindowLevel];
	[background orderFront:nil];
	NSWindow *window = [[NSWindow alloc] initWithContentRect:contentRect styleMask:NSTitledWindowMask | NSClosableWindowMask backing:NSBackingStoreBuffered defer:YES];
	[window setOpaque:NO];
	[window setBackgroundColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.0]];
	[window setDelegate:self];
	[movieView setPreservesAspectRatio:YES];
	[movieView setControllerVisible:YES];
	[window setContentView:movieView];
	QTTimeRange range = QTMakeTimeRange(QTZeroTime, [self duration]);
	QTMovie *copy = [[[QTMovie alloc] initWithMovie:self timeRange:range error:nil] autorelease];
	[movieView setMovie:copy];
	[movieView performSelector:@selector(play:) withObject:nil afterDelay:0.0 inModes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSModalPanelRunLoopMode, nil]];
	
	[window setLevel:NSModalPanelWindowLevel];
	[window center];
	[window setHasShadow:YES];
	[window setParentWindow:background];
	sRunningFullscreen = YES;
	[NSApp runModalForWindow:window];
	[background removeChildWindow:window];
	[movieView pause:nil];
	[window setContentView:nil];
	[window close];
	[background close];
	sRunningFullscreen = NO;
}

@end
//
//  ARInspector.m
//  ARInspector
//
//  Created by Simon Bovet on 06.04.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ARInspector.h"

#define kView @"View"
#define kName @"Name"
#define kIdentifier @"Identifier"
#define kSuperview @"Superview"
#define kButton @"Button"
#define kContainerView @"Container"
#define kOpenState @"State"
#define kHeight @"Height"

@interface ARInspectorTitleBackgroundView : NSView

@end

@implementation ARInspectorTitleBackgroundView

-(void)drawRect:(NSRect)inRect
{
	[[NSColor colorWithCalibratedWhite:0.75 alpha:1.0] set];
	NSRectFill(inRect);
	[[NSColor lightGrayColor] set];
	NSFrameRect([self bounds]);
}

@end

@interface ARInspector (Private)

-(void)addViews;
-(void)setupViews;

-(void)toggleViewAtIndex:(int)inIndex;

@end

@implementation ARInspector

-(id)initWithWindowNibName:(NSString *)inName
{
	if (self = [super initWithWindowNibName:inName]) {
		[self loadWindow];
		[(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:YES];
		mViews = [[NSMutableArray alloc] initWithCapacity:0];
		[self addViews];
		[self setupViews];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(savePreferences:) name:NSApplicationWillTerminateNotification object:nil];
	}
	return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[mViews release];
	[super dealloc];
}

-(BOOL)isVisible
{
	return [[self window] isVisible];
}

-(void)viewWithIdentifierWillBecomeVisible:(NSString *)inIdentifier
{
}

-(void)toggle
{
	NSWindow *window = [self window];
	if ([window isVisible])
		[window orderOut:nil];
	else {
		mOrderingFront = YES;
		NSEnumerator *enumerator = [mViews objectEnumerator];
		NSDictionary *info;
		while (info = [enumerator nextObject])
			if ([[info objectForKey:kOpenState] boolValue])
				[self viewWithIdentifierWillBecomeVisible:[info objectForKey:kIdentifier]];
		mOrderingFront = NO;
		[window orderFront:nil];
	}
}

-(void)addView:(NSView *)inView withName:(NSString *)inName identifier:(NSString *)inIdentifier openByDefault:(BOOL)inOpen
{
	[mViews addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:inView, kView, inName, kName, inIdentifier, kIdentifier, nil]];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *key = [NSString stringWithFormat:@"%@ %@ Open", [self windowNibName], inIdentifier];
	if (![defaults objectForKey:key])
		[defaults setObject:[NSNumber numberWithBool:inOpen] forKey:key];
}

-(float)maxWidth
{
	float maxWidth = 0;
	NSEnumerator *enumerator = [mViews objectEnumerator];
	NSMutableDictionary *info;
	while (info = [enumerator nextObject])
		maxWidth = MAX(maxWidth, [[info objectForKey:kView] frame].size.width);
	return maxWidth;
}

-(NSImage *)closedImage
{
	return [NSImage imageNamed:@"ARDisclosureArrowRight"];
}

-(NSImage *)openImage
{
	return [NSImage imageNamed:@"ARDisclosureArrowDown"];
}

-(void)addViews
{
	[self doesNotRecognizeSelector:_cmd];
}

-(void)increaseHeightBy:(float)inDeltaHeight animate:(BOOL)inAnimate
{
	NSWindow *window = [self window];
	NSRect windowFrame = [window frame];
	windowFrame.size.height += inDeltaHeight;
	windowFrame.origin.y -= inDeltaHeight;
	[window setFrame:windowFrame display:YES animate:inAnimate];

	NSSize size = [window minSize];
	size.height = windowFrame.size.height;
	[window setMinSize:size];
	size = [window maxSize];
	size.height = windowFrame.size.height;
	[window setMaxSize:size];
}

-(float)scaleFactor
{
	return [[self window] userSpaceScaleFactor];
}

-(void)setHeight:(float)inHeight animate:(BOOL)inAnimate
{
	float dy = inHeight - [[[self window] contentView] frame].size.height;
	[self increaseHeightBy:dy * [self scaleFactor] animate:inAnimate];
}

-(BOOL)shouldDisplayOnStartup
{
	return YES;
}

-(void)setupViews
{
	const float inset = 4;
	const float buttonHeight = 22;
	NSSize size = NSMakeSize([self maxWidth], inset);
	NSWindow *window = [self window];
	NSView *contentView = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, size.width, size.height)] autorelease];
	
	NSRect frame = [window frame];
	frame.size.width = size.width * [self scaleFactor];
	[window setFrame:frame display:YES];
	
	NSEnumerator *enumerator = [mViews reverseObjectEnumerator];
	NSMutableDictionary *info;
	BOOL first = YES;
	while (info = [enumerator nextObject]) {
		NSView *view = [info objectForKey:kView];
		[view setFrameOrigin:NSZeroPoint];
		[info setObject:[NSNumber numberWithFloat:[view frame].size.height * [self scaleFactor]] forKey:kHeight];
		
		NSRect topFrame = NSMakeRect(0, NSMaxY([view frame]), size.width, buttonHeight + inset);
		
		NSButton *button = [[[NSButton alloc] initWithFrame:NSMakeRect(inset, 0, size.width - 3 * inset, buttonHeight)] autorelease];
		[button setButtonType:NSMomentaryChangeButton];
		[button setBezelStyle:NSShadowlessSquareBezelStyle];
		[button setImagePosition:NSImageLeft];
		[button setAlignment:NSLeftTextAlignment];
		[button setImage:[self openImage]];
		[button setTitle:[info objectForKey:kName]];
		[button setTag:[mViews indexOfObjectIdenticalTo:info]];
		[button setTarget:self];
		[button setAction:@selector(toggleView:)];
		[button setBordered:NO];
		[button setFocusRingType:NSFocusRingTypeNone];
		[button setAutoresizingMask:NSViewWidthSizable];
		[info setObject:button forKey:kButton];

		NSView *topView = [[[NSView alloc] initWithFrame:topFrame] autorelease];
		[topView setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
		NSView *backgroundView = [[[ARInspectorTitleBackgroundView alloc] initWithFrame:NSMakeRect(inset, 0, size.width - 2 * inset, buttonHeight)] autorelease];
		[backgroundView addSubview:button];
		[backgroundView setAutoresizingMask:NSViewWidthSizable];		
		[topView addSubview:backgroundView];
		
		NSRect bottomFrame = [view frame];
		bottomFrame.size.width = size.width;
		NSView *bottomView = [[[NSView alloc] initWithFrame:bottomFrame] autorelease];
		[bottomView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		[bottomView addSubview:view];
		
		NSRect containerFrame = bottomFrame;
		containerFrame.size.height = NSMaxY(topFrame);
		containerFrame.origin.y = size.height;
		size.height += containerFrame.size.height;
		NSView *container = [[[NSView alloc] initWithFrame:containerFrame] autorelease];
		[container setAutoresizingMask:NSViewWidthSizable];
		[container addSubview:topView];
		[container addSubview:bottomView];
		[info setObject:container forKey:kContainerView];
		
		[contentView addSubview:container];
		[info setObject:[view superview] forKey:kSuperview];
		[info setObject:[NSNumber numberWithBool:YES] forKey:kOpenState];
		first = NO;
	}
	
	[contentView setAutoresizingMask:NSViewWidthSizable];
	[contentView setFrameSize:size];
	[self setHeight:size.height animate:NO];
	[window setContentView:contentView];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *topLeftCoordinates = [defaults objectForKey:[NSString stringWithFormat:@"%@ TopLeft", [self windowNibName]]];
	if (topLeftCoordinates)
		[window setFrameTopLeftPoint:NSPointFromString(topLeftCoordinates)];
	enumerator = [mViews objectEnumerator];
	while (info = [enumerator nextObject]) {
		NSString *key = [NSString stringWithFormat:@"%@ %@ Open", [self windowNibName], [info objectForKey:kIdentifier]];
		NSNumber *openState = [defaults objectForKey:key];
		if (openState && ![openState boolValue])
			[self toggleViewAtIndex:[mViews indexOfObjectIdenticalTo:info]];
	}
	NSNumber *width = [defaults objectForKey:[NSString stringWithFormat:@"%@ Width", [self windowNibName]]];
	if (width) {
		NSRect frame = [[self window] frame];
		frame.size.width = [width floatValue];
		[[self window] setFrame:frame display:NO];
	}
	if ([[defaults objectForKey:[NSString stringWithFormat:@"%@ Visible", [self windowNibName]]] boolValue] && [self shouldDisplayOnStartup])
		[self toggle];
}

-(void)toggleViewAtIndex:(int)inIndex
{
	NSView *obsoleteView = nil;
	float deltaHeight = 0;
	int i, n = [mViews count];
	for (i = 0; i < n; i++) {
		NSMutableDictionary *info = [mViews objectAtIndex:i];
		unsigned int mask;
		if (i < inIndex)
			mask = NSViewMinYMargin;
		else if (i == inIndex) {
			mask = NSViewHeightSizable;
			BOOL openState = ![[info objectForKey:kOpenState] boolValue];
			deltaHeight = [[info objectForKey:kHeight] floatValue];
			NSView *view = [info objectForKey:kView];
			if (openState) {
				NSView *superview = [info objectForKey:kSuperview];
				NSSize size = [view frame].size;
				size.width = [superview bounds].size.width;
				[view setFrameSize:size];
				[superview addSubview:view];
			} else
				obsoleteView = view;
			[info setObject:[NSNumber numberWithBool:openState] forKey:kOpenState];
			if (openState)
				[self viewWithIdentifierWillBecomeVisible:[info objectForKey:kIdentifier]];
			NSButton *button = [info objectForKey:kButton];
			[button setImage:openState ? [self openImage] : [self closedImage]];
			if (!openState)
				deltaHeight *= -1;
		} else
			mask = NSViewMaxYMargin;
		[[info objectForKey:kContainerView] setAutoresizingMask:mask | NSViewWidthSizable];
	}

	[self increaseHeightBy:deltaHeight animate:YES];
	[obsoleteView removeFromSuperview];
}

-(void)toggleView:(id)inSender
{
	[self toggleViewAtIndex:[inSender tag]];
}

-(void)savePreferences:(NSNotification *)inNotification
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSRect windowFrame = [[self window] frame];
	NSString *topLeftCoordinates = NSStringFromPoint(NSMakePoint(NSMinX(windowFrame), NSMaxY(windowFrame)));
	[defaults setObject:topLeftCoordinates forKey:[NSString stringWithFormat:@"%@ TopLeft", [self windowNibName]]];
	[defaults setObject:[NSNumber numberWithFloat:[[self window] frame].size.width] forKey:[NSString stringWithFormat:@"%@ Width", [self windowNibName]]];
	[defaults setObject:[NSNumber numberWithBool:[self isVisible]] forKey:[NSString stringWithFormat:@"%@ Visible", [self windowNibName]]];
	
	NSEnumerator *enumerator = [mViews objectEnumerator];
	NSDictionary *info;
	while (info = [enumerator nextObject]) {
		NSString *key = [NSString stringWithFormat:@"%@ %@ Open", [self windowNibName], [info objectForKey:kIdentifier]];
		[defaults setObject:[info objectForKey:kOpenState] forKey:key];
	}
}

-(BOOL)isViewVisibleWithIdentifier:(NSString *)inIdentifier
{
	if (![self isVisible] && !mOrderingFront)
		return NO;
	NSEnumerator *enumerator = [mViews objectEnumerator];
	NSDictionary *info;
	while (info = [enumerator nextObject])
		if ([[info objectForKey:kIdentifier] isEqualToString:inIdentifier])
			return [[info objectForKey:kOpenState] boolValue];
	return NO;
}

@end

@implementation ARInspectorPanel

-(NSRect)constrainFrameRect:(NSRect)inFrameRect toScreen:(NSScreen *)inScreen
{
	NSRect frame = inFrameRect;
	if (!inScreen)
		inScreen = [NSScreen mainScreen];
	NSRect screen = [inScreen frame];
	frame.origin.x = MAX(frame.origin.x, NSMinX(screen) - frame.size.width + 20);
	frame.origin.x = MIN(frame.origin.x, NSMaxX(screen) - 20);
	frame.origin.y = MAX(frame.origin.y, NSMinY(screen) - frame.size.height + 20);
	frame.origin.y = MIN(frame.origin.y, NSMaxY(screen) - frame.size.height);
	return frame;
}

@end

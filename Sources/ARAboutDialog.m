//
//  ARAboutDialog.m
//  Curvus Pro X
//
//  Created by Simon Bovet on Wed Jun 04 2003.
//  Copyright (c) 2003 Arizona. All rights reserved.
//

#import "ARAboutDialog.h"

#import "BezierPathExtensions.h"

#define ARLocalizedString(key, comment) NSLocalizedStringFromTable(key, @"ARLocalizable", comment)

@interface NSWindow (ARAboutDialog)

-(void)animateAlphaValueFrom:(float)inFrom to:(float)inTo during:(NSTimeInterval)inInterval;

@end

@implementation NSWindow (ARAboutDialog)

-(void)animateAlphaValueFrom:(float)inFrom to:(float)inTo during:(NSTimeInterval)inInterval
{
    NSDate *start = [NSDate date];
    float k = 0;
    while (k < 1.0) {
        k = MIN(1.0, -[start timeIntervalSinceNow] / inInterval);
        [self setAlphaValue:inFrom + k * (inTo - inFrom)];
    }
    [self setAlphaValue:inTo];
}

@end

@implementation ARAboutDialog

+(id)sharedAboutDialog
{
    static ARAboutDialog *sharedDialog = nil;
    
    if (!sharedDialog) {
        sharedDialog = [[[self class] allocWithZone:[self zone]] init];
        [sharedDialog window];
    }
        
    return sharedDialog;
}

-(NSString *)windowNibName
{
    return @"ARAbout";
}

-(id)init
{
    NSString *windowNibName = [self windowNibName];
    
    if (!windowNibName)
        return nil;
        
    if (self = [self initWithWindowNibName:windowNibName])
        [self setWindowFrameAutosaveName:windowNibName];
    return self;
}

-(void)windowDidLoad
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Credits"
                                                ofType:@"rtf"
                                                inDirectory:@""];
    [mCreditsScroll setDrawsBackground:NO];
    [mCredits setDrawsBackground:NO];
    [mCredits readRTFDFromFile:path];

    CFBundleRef localInfoBundle = CFBundleGetMainBundle();
    NSDictionary *localInfoDict = (NSDictionary *)CFBundleGetLocalInfoDictionary(localInfoBundle);
    [mAppName setStringValue:[localInfoDict objectForKey:@"CFBundleName"]];
    [mAppVersion setStringValue:[NSString stringWithFormat:ARLocalizedString(@"VERSION_%@", @""),
                            [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]];
}

-(void)displayAboutWindow:(BOOL)inAnimateAlpha
{
    [mCreditsScroll setVerticalScroll:0.0];
	NSWindow *window = [self window];
	[window setLevel:NSModalPanelWindowLevel];
    [window setAlphaValue:inAnimateAlpha ? 0.0 : 1.0];
    [window center];
    [window orderFront:nil];
    if (inAnimateAlpha)
        [window animateAlphaValueFrom:0.0 to:1.0 during:0.12];
}

-(void)hideAboutWindow:(BOOL)inAnimateAlpha
{
    if (inAnimateAlpha)
        [[self window] animateAlphaValueFrom:1.0 to:0.0 during:0.4];
    [[self window] close];
}

-(void)showAboutWindow
{
    [self displayAboutWindow:YES];

    float dt = 0.05; // s
    float speed = 20.0; // px / s
    float delay = 2.0; // s
	int dir = 1;
    
    float scroll = -speed * delay;
    NSDate *date = [NSDate date];
	NSEvent *event;
	for (;;) {
again:
    	event = [[self window] nextEventMatchingMask:NSLeftMouseDownMask | NSRightMouseDownMask | NSKeyDownMask | NSFlagsChangedMask
                            untilDate:date inMode:NSDefaultRunLoopMode dequeue:YES];
		if (event)
			if ([event type] == NSFlagsChanged) {
				dir = ([event modifierFlags] & NSCommandKeyMask) != 0 ? 0 : ([event modifierFlags] & NSAlternateKeyMask) == 0 ? 1 : -1;
				if (([event modifierFlags] & NSShiftKeyMask) != 0)
					dir *= 2;
				goto again;
			} else
				break;
        [mCreditsScroll setVerticalScroll:MAX(0, scroll)];
		scroll += dir * speed * dt;
        date = [date addTimeInterval:dt];
    }
    
    [self hideAboutWindow:YES];
}

-(void)displaySecretAboutWindow:(BOOL)inAnimateAlpha
{
    [mSecretWindow setAlphaValue:inAnimateAlpha ? 0.0 : 1.0];
    [mSecretWindow center];
    [mSecretWindow orderFront:nil];
    if (inAnimateAlpha)
        [mSecretWindow animateAlphaValueFrom:0.0 to:1.0 during:0.12];
}

-(void)hideSecretAboutWindow:(BOOL)inAnimateAlpha
{
    if (inAnimateAlpha)
        [mSecretWindow animateAlphaValueFrom:1.0 to:0.0 during:0.4];
    [mSecretWindow close];
}

-(void)showSecretAboutWindow
{
    [self displaySecretAboutWindow:YES];
    NSDate *date = [NSDate date];
    while (![[self window] nextEventMatchingMask:NSLeftMouseDownMask | NSRightMouseDownMask | NSKeyDownMask
                            untilDate:date inMode:NSDefaultRunLoopMode dequeue:YES])
        ;
    [self hideSecretAboutWindow:YES];
}

-(void)show:(id)inSender
{
	[self displayAboutWindow:YES];
}

-(void)hide:(id)inSender
{
	[self hideAboutWindow:YES];
}

@end

@implementation ARAboutWindow

-(id)initWithContentRect:(NSRect)inContentRect styleMask:(unsigned int)inStyle 	backing:(NSBackingStoreType)inBufferingType defer:(BOOL)inFlag
{
    if (self = [super initWithContentRect:inContentRect styleMask:NSBorderlessWindowMask
                        backing:NSBackingStoreBuffered defer:NO]) {
        [self setLevel:NSFloatingWindowLevel];
        [self setOpaque:NO];
		[self setBackgroundColor:[NSColor clearColor]];
    }
    return self;
}

-(BOOL)canBecomeKeyWindow
{
    return YES;
}

@end

@implementation ARAboutView

-(BOOL)isOpaque
{
    return NO;
}

-(void)drawRect:(NSRect)inRect
{
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundRectInRect:[self bounds] radius:5];
    [[NSColor colorWithCalibratedWhite:0.25 alpha:0.75] set];
    [path fill];
}

@end

@implementation ARCreditsScrollView

-(void)setVerticalScroll:(float)inValue
{
    [[self contentView] scrollToPoint:NSMakePoint(0.0, inValue)];
}

@end
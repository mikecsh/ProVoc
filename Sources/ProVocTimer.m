//
//  ProVocTimer.m
//  ProVoc
//
//  Created by Simon Bovet on 15.05.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ProVocTimer.h"

#define ProVocTimerWindowOrigin @"ProVocTimerWindowOrigin"

@implementation ProVocTimer

-(id)init
{
	if (self = [super initWithWindowNibName:@"ProVocTimer"]) {
		[self window];
		NSRect rect = NSZeroRect;
		rect.size = [mTimerView frame].size;
		NSString *origin = [[NSUserDefaults standardUserDefaults] objectForKey:ProVocTimerWindowOrigin];
		if (origin)
			rect.origin = NSPointFromString(origin);
		else {
			NSRect screen = [[NSScreen mainScreen] frame];
			rect.origin.x = NSMaxX(screen) - rect.size.width - 40;
			rect.origin.y = NSMaxY(screen) - rect.size.height - 40;
		}
		mWindow = [[NSPanel alloc] initWithContentRect:rect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
		rect = [[self window] constrainFrameRect:[mWindow frame] toScreen:[NSScreen mainScreen]];
		[mWindow setFrame:rect display:NO];
		[mWindow setLevel:NSModalPanelWindowLevel + 1];
		[mWindow setBackgroundColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
		[mWindow setOpaque:NO];
		[mWindow setMovableByWindowBackground:YES];
		[mWindow setContentView:mTimerView];
		[mWindow setHasShadow:NO];
		mPauseTime = 0;
		mNotifyElapse = YES;
		mAdditionalTime = 0;
	}
	return self;
}

-(void)dealloc
{
	[mWindow release];
	[super dealloc];
}

-(void)setRemainingTime:(NSTimeInterval)inTimeInterval
{
	mNotifyElapse = YES;
	mRemainingTime = inTimeInterval + 0.9;
	[mTimerView setCountingDown:YES];
}

-(void)addRemainingTime:(NSTimeInterval)inTimeInterval
{
	mAdditionalTime += inTimeInterval + 0.9;
	mNotifyElapse = YES;
	[self start];
}

-(void)pause:(BOOL)inHide
{
	mPauseTime = [NSDate timeIntervalSinceReferenceDate];
	if (inHide)
		[mWindow orderOut:nil];
	[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(idle:) object:nil];
	NSString *origin = NSStringFromPoint([mWindow frame].origin);
	[[NSUserDefaults standardUserDefaults] setObject:origin forKey:ProVocTimerWindowOrigin];
}

-(void)idle:(id)inSender
{
	NSTimeInterval elapsed = [NSDate timeIntervalSinceReferenceDate] - mStartTime;
	if (mRemainingTime > 0)
		elapsed = mRemainingTime + mAdditionalTime - elapsed;
	[mTimerView setTime:elapsed];
	if (elapsed >= 0) {
		static NSArray *modes = nil;
		if (!modes)
			modes = [[NSArray alloc] initWithObjects:NSDefaultRunLoopMode, NSModalPanelRunLoopMode, nil];
		[self performSelector:_cmd withObject:nil afterDelay:1.0 inModes:modes];
	} else if (mNotifyElapse) {
		mNotifyElapse = NO;
		[self pause:NO];
		[[NSNotificationCenter defaultCenter] postNotificationName:ProVocTimerRemainingTimeDidElapseNotification object:self];
	}
}

-(void)start
{
	if (mPauseTime == 0) {
		mStartTime = [NSDate timeIntervalSinceReferenceDate];
		mNotifyElapse = YES;
		mAdditionalTime = 0;
	} else
		mStartTime += [NSDate timeIntervalSinceReferenceDate] - mPauseTime;
	[self idle:nil];
	[mWindow orderFront:nil];
}

-(void)pause
{
	[self pause:NO];
	mPauseTime = 0;
}

-(void)stop
{
	[self pause:YES];
}

-(void)hide
{
	[mWindow orderOut:nil];
}

@end

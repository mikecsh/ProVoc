//
//  ProVocActionController.m
//  ProVoc
//
//  Created by Simon Bovet on 03.11.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import "ProVocActionController.h"


@implementation ProVocActionController

+(id)actionControllerWithTitle:(NSString *)inTitle modalWindow:(NSWindow *)inWindow delegate:(id)inDelegate cancelSelector:(SEL)inCancelSelector
{
	ProVocActionController *controller = [[[self alloc] initWithTitle:inTitle delegate:inDelegate cancelSelector:inCancelSelector] autorelease];
	[NSApp beginSheet:[controller window] modalForWindow:inWindow modalDelegate:controller didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
	return controller;
}

-(id)initWithTitle:(NSString *)inTitle delegate:(id)inDelegate cancelSelector:(SEL)inCancelSelector
{
	if (self = [super initWithWindowNibName:@"ProVocAction"]) {
		mActionTitle = [inTitle retain];
		mDelegate = inDelegate;
		mCancelSelector = inCancelSelector;
	}
	return self;
}

-(NSString *)actionTitle
{
	return mActionTitle;
}

-(float)progress
{
	return mProgress;
}

-(void)setProgress:(id)inProgress
{
	float progress = [inProgress floatValue];
	if (mProgress != progress) {
		[self willChangeValueForKey:@"progress"];
		mProgress = progress;
		[self didChangeValueForKey:@"progress"];
	}
}

-(void)finish
{
	[NSApp endSheet:[self window] returnCode:NSOKButton];
}

-(void)sheetDidEnd:(NSWindow *)inSheet returnCode:(int)inReturnCode contextInfo:(void *)inContextInfo
{
	[inSheet orderOut:nil];
	if (inReturnCode == NSCancelButton)
		[mDelegate performSelector:mCancelSelector withObject:self];
}

-(IBAction)cancel:(id)inSender
{
	[NSApp endSheet:[self window] returnCode:NSCancelButton];
}

@end

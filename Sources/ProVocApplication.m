//
//  ProVocApplication.m
//  ProVoc
//
//  Created by Simon Bovet on 14.10.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import "ProVocApplication.h"

#import "ProVocTextField.h"
#import "ProVocInspector.h"
#import "ProVocTester.h"
#import "ProVocFontNameField.h"

@interface ProVocResponder : NSResponder {
	int mFirstResponderChange;
}

-(int)firstResponderChange;

@end

@implementation ProVocResponder

-(int)firstResponderChange
{
	return mFirstResponderChange;
}

-(void)insertTab:(id)inSender
{
	mFirstResponderChange = 1;
}

-(void)insertBacktab:(id)inSender
{
	mFirstResponderChange = -1;
}

-(void)doCommandBySelector:(SEL)inSelector
{
	if ([self respondsToSelector:inSelector])
		[self performSelector:inSelector withObject:nil];
}

-(void)insertText:(NSString *)inText
{
}

@end


@implementation ProVocApplication

-(BOOL)sendAction:(SEL)inAction to:(id)inTarget from:(id)inSender
{
	if (inAction == @selector(changeFont:) && [ProVocFontNameField changeFont:inSender])
		return YES;
	return [super sendAction:inAction to:inTarget from:inSender];
}

-(void)sendEvent:(NSEvent *)inEvent
{
	if ([inEvent type] == NSKeyDown) {
		ProVocResponder *responder = [[[ProVocResponder alloc] init] autorelease];
		[responder interpretKeyEvents:@[inEvent]];
		if ([responder firstResponderChange] != 0) {
			id firstResponder = [[NSApp keyWindow] firstResponder];
			if ([firstResponder respondsToSelector:@selector(delegate)])
				firstResponder = [firstResponder delegate];
			if ([firstResponder isKindOfClass:[ProVocTextField class]]) {
				id next = [firstResponder chainedResponder:[responder firstResponderChange]];
				[[firstResponder window] performSelector:@selector(makeFirstResponder:) withObject:next afterDelay:0.0];
				return;
			}
		}

		NSEnumerator *enumerator = [[ProVocTester currentTesters] objectEnumerator];
		ProVocTester *tester;
		while (tester = [enumerator nextObject])
			if ([tester handleKeyDownEvent:inEvent])
				return;

		if ([[ProVocInspector sharedInspector] handleKeyDownEvent:inEvent])
			return;
	}
	NS_DURING
		[super sendEvent:inEvent];
	NS_HANDLER
	NS_ENDHANDLER
}

@end

@implementation NSApplication (ProVoc)

+(NSApplication *)sharedApplication
{
	static NSApplication *sharedApplication = nil;
	if (!sharedApplication)
		sharedApplication = [[ProVocApplication alloc] init];
	return sharedApplication;
}

-(long)systemVersion
{
	static long systemVersion = 0;
	if (systemVersion == 0)
		Gestalt(gestaltSystemVersion, &systemVersion);
	return systemVersion;
}

@end


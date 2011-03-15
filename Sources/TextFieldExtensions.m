//
//  TextFieldExtensions.m
//  ProVoc
//
//  Created by Simon Bovet on 14.02.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "TextFieldExtensions.h"

#import "MenuExtensions.h"
#import "SpeechSynthesizerExtensions.h"

@implementation NSTextField (ProVoc)

-(NSMenu *)menu
{
	NSMenu *menu = [super menu];
	if (!menu)
		menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	if ([menu numberOfItems] > 0)
		[menu addItem:[NSMenuItem separatorItem]];
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
	[[self speechSynthesizer] stopSpeaking]; // ++++ v4.2.2 ++++
	[[self speechSynthesizer] startSpeakingString:[self stringValue]];
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

-(void)setWritingDirection:(NSWritingDirection)inDirection
{
	[[self cell] setBaseWritingDirection:inDirection];
	[[self cell] setAlignment:inDirection == NSWritingDirectionRightToLeft ? NSRightTextAlignment : NSLeftTextAlignment];
}

@end

//
//  ProVocFontNameField.m
//  ProVoc
//
//  Created by Simon Bovet on 27.11.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import "ProVocFontNameField.h"

@implementation ProVocFontNameField

static ProVocFontNameField *sCurrentField = nil;

-(float)currentFontSize
{
	id value = [[mObservedObjects objectForKey:@"fontSize"] valueForKeyPath:[mObservedKeyPaths objectForKey:@"fontSize"]];
	return value ? [value floatValue] : 0.0;
}

-(NSString *)currentFontFamilyName
{
	return [[mObservedObjects objectForKey:@"fontFamilyName"] valueForKeyPath:[mObservedKeyPaths objectForKey:@"fontFamilyName"]];
}

-(NSFont *)currentFont
{
	NSFont *font = [NSFont systemFontOfSize:[self currentFontSize]];
	font = [[NSFontManager sharedFontManager] convertFont:font toFamily:[self currentFontFamilyName]];
	return font;
}

-(IBAction)userSetFont:(id)inSender
{
	if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0) {
		[[mObservedObjects objectForKey:@"fontFamilyName"] setValue:[[NSFont systemFontOfSize:0] familyName] forKeyPath:[mObservedKeyPaths objectForKey:@"fontFamilyName"]];
		[[mObservedObjects objectForKey:@"fontSize"] setValue:[NSNumber numberWithFloat:[NSFont systemFontSize]] forKeyPath:[mObservedKeyPaths objectForKey:@"fontSize"]];
		return;
	}
	
	NSFontManager *manager = [NSFontManager sharedFontManager];
	NSFont *font = [self currentFont];
	if (font)
		[manager setSelectedFont:font isMultiple:NO];
    [manager orderFrontFontPanel:self];
	[[self window] makeFirstResponder:self];
	sCurrentField = self;
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

-(void)dealloc
{
	[mObservedObjects release];
	[mObservedKeyPaths release];
	if (sCurrentField == self)
		sCurrentField = nil;
	[super dealloc];
}

-(void)bind:(NSString *)inBinding toObject:(id)inObservable withKeyPath:(NSString *)inKeyPath options:(NSDictionary *)inOptions
{
	if (!mObservedObjects) {
		mObservedObjects = [[NSMutableDictionary alloc] initWithCapacity:0];
		mObservedKeyPaths = [[NSMutableDictionary alloc] initWithCapacity:0];
	}
	[mObservedObjects setObject:inObservable forKey:inBinding];
	[mObservedKeyPaths setObject:inKeyPath forKey:inBinding];
	[super bind:inBinding toObject:inObservable withKeyPath:inKeyPath options:inOptions];
}

-(void)changeFont:(id)inSender
{
	NSFont *font = [self currentFont];
	font = [inSender convertFont:font];
	NSString *familyName = [font familyName];
	if (familyName) {
		[self setStringValue:familyName];
		[[mObservedObjects objectForKey:@"fontFamilyName"] setValue:familyName forKeyPath:[mObservedKeyPaths objectForKey:@"fontFamilyName"]];
	}
	[[mObservedObjects objectForKey:@"fontSize"] setValue:[NSNumber numberWithFloat:[font pointSize]] forKeyPath:[mObservedKeyPaths objectForKey:@"fontSize"]];
}

+(BOOL)changeFont:(id)inSender
{
	if ([[sCurrentField window] isVisible]) {
		[sCurrentField changeFont:inSender];
		return YES;
	}
	return NO;
}

@end

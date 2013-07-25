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
	id value = [mObservedObjects[@"fontSize"] valueForKeyPath:mObservedKeyPaths[@"fontSize"]];
	return value ? [value floatValue] : 0.0;
}

-(NSString *)currentFontFamilyName
{
	return [mObservedObjects[@"fontFamilyName"] valueForKeyPath:mObservedKeyPaths[@"fontFamilyName"]];
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
		[mObservedObjects[@"fontFamilyName"] setValue:[[NSFont systemFontOfSize:0] familyName] forKeyPath:mObservedKeyPaths[@"fontFamilyName"]];
		[mObservedObjects[@"fontSize"] setValue:[NSNumber numberWithFloat:[NSFont systemFontSize]] forKeyPath:mObservedKeyPaths[@"fontSize"]];
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
	mObservedObjects[inBinding] = inObservable;
	mObservedKeyPaths[inBinding] = inKeyPath;
	[super bind:inBinding toObject:inObservable withKeyPath:inKeyPath options:inOptions];
}

-(void)changeFont:(id)inSender
{
	NSFont *font = [self currentFont];
	font = [inSender convertFont:font];
	NSString *familyName = [font familyName];
	if (familyName) {
		[self setStringValue:familyName];
		[mObservedObjects[@"fontFamilyName"] setValue:familyName forKeyPath:mObservedKeyPaths[@"fontFamilyName"]];
	}
	[mObservedObjects[@"fontSize"] setValue:[NSNumber numberWithFloat:[font pointSize]] forKeyPath:mObservedKeyPaths[@"fontSize"]];
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

//
//  ProVocDocument+Presets.m
//  ProVoc
//
//  Created by Simon Bovet on 26.01.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ProVocDocument+Presets.h"

#import "ProVocPreset.h"
#import "StringExtensions.h"

@interface ProVocDocument (PresetsExtern)

-(BOOL)canModifyTestParameters;

@end

@implementation ProVocDocument (Presets)

-(void)createPresetWithName:(NSString *)inName
{
	if (![self canModifyTestParameters]) {
		NSBeep();
		return;
	}
	[self willChangePresets];
	ProVocPreset *preset = [[[ProVocPreset alloc] init] autorelease];
	[preset setName:inName];
	[preset setParameters:[self parameters]];
	[mPresets addObject:preset];
	mIndexOfCurrentPresets = [mPresets indexOfObjectIdenticalTo:preset];
	[self presetsDidChange:nil];
	[self didChangePresets];
	[self editPreset:nil];
}

-(IBAction)newPreset:(id)inSender
{
	[self createPresetWithName:[NSString stringWithFormat:NSLocalizedString(@"Preset Default Name %i", @""), [[self presets] count] + 1]];
/*	[self requestNewName:NSLocalizedString(@"New Preset Prompt", @"")
			defaultName:[NSString stringWithFormat:NSLocalizedString(@"Preset Default Name %i", @""), [[self presets] count] + 1]
			callbackSelector:@selector(createPresetWithName:)];*/
}

-(IBAction)editPreset:(id)inSender
{
	[self setEditingPreset:YES];
}

-(IBAction)duplicatePreset:(id)inSender
{
	if (![self canModifyTestParameters]) {
		NSBeep();
		return;
	}
	[self willChangePresets];
	NSMutableArray *names = [NSMutableArray array];
	NSEnumerator *enumerator = [mPresets objectEnumerator];
	ProVocPreset *preset;
	while (preset = [enumerator nextObject])
		[names addObject:[preset name]];
		
	ProVocPreset *copy = [[[mPresets objectAtIndex:mIndexOfCurrentPresets] copy] autorelease];
	[copy setName:[[copy name] nameOfCopyWithExistingNames:names]];
	[mPresets insertObject:copy atIndex:++mIndexOfCurrentPresets];
	[self presetsDidChange:nil];
	[self didChangePresets];
}

-(BOOL)canRemovePreset
{
	return [mPresets count] > 1 && [self canModifyTestParameters];
}

-(IBAction)removePreset:(id)inSender
{
	if (![self canRemovePreset]) {
		NSBeep();
		return;
	}
	
	[self willChangePresets];
	[mPresets removeObjectAtIndex:mIndexOfCurrentPresets];
	mIndexOfCurrentPresets = MIN(mIndexOfCurrentPresets, [mPresets count] - 1);
	[self presetsDidChange:nil];
	[self didChangePresets];
}

-(void)addDefaultPresetIfNecessary
{
	if ([mPresets count] == 0) {
		NSString *path = [[NSBundle mainBundle] pathForResource:@"DefaultPresets" ofType:@"xml" inDirectory:@""];
		NSArray *defaultPresets = [NSArray arrayWithContentsOfFile:path];
		NSEnumerator *enumerator = [defaultPresets objectEnumerator];
		NSDictionary *defaultPreset;
		while (defaultPreset = [enumerator nextObject]) {
			ProVocPreset *preset = [[[ProVocPreset alloc] init] autorelease];
			[preset setName:[defaultPreset objectForKey:@"Name"]];
			NSMutableDictionary *parameters = [[[self parameters] mutableCopy] autorelease];
			[parameters setValuesForKeysWithDictionary:[defaultPreset objectForKey:@"Parameters"]];
			[preset setParameters:parameters];
			[mPresets addObject:preset];
		}
		[self setParameters:[[mPresets objectAtIndex:mIndexOfCurrentPresets = 0] parameters]];
	}
}

-(id)presets
{
	if (!mPresets) {
		mPresets = [[NSMutableArray alloc] initWithCapacity:0];
		[self addDefaultPresetIfNecessary];
	}
	return mPresets;
}

-(void)setPresets:(id)inPresets
{
	[self presets];
	if (inPresets)
		[mPresets setArray:inPresets];
	[self addDefaultPresetIfNecessary];
	[self presetsDidChange:nil];
}

-(void)currentPresetValuesDidChange:(id)inSender
{
	[[mPresets objectAtIndex:mIndexOfCurrentPresets] setParameters:[self parameters]];
	[self currentPresetDidChange:inSender];
}

-(void)currentPresetDidChange:(id)inSender
{
	[self presetsDidChange:inSender];
}

-(void)presetsDidChange:(id)inSender
{
	[self willChangeValueForKey:@"presetName"];
	[mPresetTableView reloadData];
	[mPresetTableView selectRow:mIndexOfCurrentPresets byExtendingSelection:NO];
	[self didChangeValueForKey:@"presetName"];
	[self setParameters:[[mPresets objectAtIndex:mIndexOfCurrentPresets] parameters]];
}

-(id)presetSettings
{
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:mIndexOfCurrentPresets], @"IndexOfCurrentPresets",
									[self presets], @"Presets", nil];
}

-(void)setPresetSettings:(id)inPresetSettings
{
	mIndexOfCurrentPresets = [[inPresetSettings objectForKey:@"IndexOfCurrentPresets"] unsignedIntValue];
	[self setPresets:[inPresetSettings objectForKey:@"Presets"]];
}

-(NSString *)presetName
{
	return [[mPresets objectAtIndex:mIndexOfCurrentPresets] name];
}

-(void)setPresetName:(NSString *)inName
{
	[(ProVocPreset *)[mPresets objectAtIndex:mIndexOfCurrentPresets] setName:inName];
	[self currentPresetDidChange:nil];
}

@end

@implementation ProVocDocument (SplitViewDelegate)

-(BOOL)splitView:(NSSplitView *)inSplitView canCollapseSubview:(NSView *)inView
{
	return NO;
}

-(float)splitView:(NSSplitView *)inSplitView constrainMinCoordinate:(float)inProposedMin ofSubviewAt:(int)inOffset
{
	return 150;
}

-(float)splitView:(NSSplitView *)inSplitView constrainMaxCoordinate:(float)inProposedMin ofSubviewAt:(int)inOffset
{
	return [[inSplitView window] frame].size.width - ([mPresetEditView frame].size.width + 150);
}

-(void)splitViewWillResizeSubviews:(NSNotification *)inNotification
{
	NSSplitView *splitView = [inNotification object];
	float minWidth = [mPresetEditView frame].size.width + 150;
	NSView *subview = [[splitView subviews] objectAtIndex:1];
	if ([subview frame].size.width < minWidth) {
		[subview setFrameSize:NSMakeSize(minWidth, [subview frame].size.height)];
		[splitView adjustSubviews];
	}
}

@end

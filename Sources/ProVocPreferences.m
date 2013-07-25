//
//  ProVocPreferences.m
//  ProVoc
//
//  Created by bovet on Mon Feb 10 2003.
//  Copyright (c) 2003 Arizona Software. All rights reserved.
//

#import "ProVocPreferences.h"
#import "ProVocDocument+Lists.h"
#import "ProVocInspector.h"
#import "ProVocBackground.h"
#import "ProVocStartingPoint.h"

@implementation ProVocPreferences

+ (ProVocPreferences*)sharedPreferences
{
    static ProVocPreferences *_sharedProVocPreferences = NULL;
    
    if(!_sharedProVocPreferences)
        _sharedProVocPreferences = [[ProVocPreferences alloc] init];
    
    return _sharedProVocPreferences;
}

-(id)init
{
    if (self = [self initWithWindowNibName:@"Preferences"]) {
		[self loadWindow];

		mPaneViews = [[NSArray alloc] initWithObjects:mGeneralView, mTrainingView, mLanguageView, mFontView, mLabelView, nil];
		mPaneImageNames = [[NSArray alloc] initWithObjects:@"Preferences", @"TrainingPreferences", @"LanguagePreferences", @"FontPreferences", @"LabelPreferences", nil];
		mPaneLabels = [[NSArray alloc] initWithObjects:
							NSLocalizedString(@"General Preference Pane Label", @""),
							NSLocalizedString(@"Training Preference Pane Label", @""),
							NSLocalizedString(@"Language Preference Pane Label", @""),
							NSLocalizedString(@"Font Preference Pane Label", @""),
							NSLocalizedString(@"Label Preference Pane Label", @""),
						nil];

		[self setupToolbar];
		[self selectPaneAtIndex:0];

		NSButtonCell *switchCell = [[[NSButtonCell alloc] initTextCell:@""] autorelease];
		[switchCell setControlSize:NSSmallControlSize];
		[switchCell setButtonType:NSSwitchButton];
		[switchCell setAllowsMixedState:NO];
		
		[mLanguageTableView setDataSource:self];
		[[mLanguageTableView tableColumnWithIdentifier:PVCaseSensitive] setDataCell:switchCell];
		[[mLanguageTableView tableColumnWithIdentifier:PVAccentSensitive] setDataCell:switchCell];
		[[mLanguageTableView tableColumnWithIdentifier:PVPunctuationSensitive] setDataCell:switchCell];
		[[mLanguageTableView tableColumnWithIdentifier:PVSpaceSensitive] setDataCell:switchCell];
		[mLanguageTableView reloadData];

		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.Labels" options:NSKeyValueObservingOptionNew context:nil];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.sourceFontFamilyName" options:NSKeyValueObservingOptionNew context:nil];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.sourceFontSize" options:NSKeyValueObservingOptionNew context:nil];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.sourceTestFontSize" options:NSKeyValueObservingOptionNew context:nil];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.targetFontFamilyName" options:NSKeyValueObservingOptionNew context:nil];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.targetFontSize" options:NSKeyValueObservingOptionNew context:nil];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.targetTestFontSize" options:NSKeyValueObservingOptionNew context:nil];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.commentFontFamilyName" options:NSKeyValueObservingOptionNew context:nil];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.commentFontSize" options:NSKeyValueObservingOptionNew context:nil];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.commentTestFontSize" options:NSKeyValueObservingOptionNew context:nil];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.PVPrefsRightRatio" options:NSKeyValueObservingOptionNew context:nil];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.StartingPoint" options:NSKeyValueObservingOptionNew context:nil];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.reviewLearningFactor" options:NSKeyValueObservingOptionNew context:nil];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.reviewTrainingFactor" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

-(void)dealloc
{
	[super dealloc];
}

- (IBAction)updateDifficulty:(id)sender
{	
    [[NSNotificationCenter defaultCenter] postNotificationName:PVRightRatioDidChangeNotification object:nil];
}

-(IBAction)showWindow:(id)inSender
{
	[self flagsChanged:[NSApp currentEvent]];
	[super showWindow:inSender];
}

-(IBAction)restoreDefaultLabels:(id)inSender
{
	int i;
	for (i = 1; i < 10; i++) {
		NSString *title = [NSString stringWithFormat:@"Label %i Default Title", i];
		NSString *key = [NSString stringWithFormat:@"labelTitle%i", i];
		[self setValue:NSLocalizedString(title, @"") forKey:key];
	}
}

-(void)openGeneralView:(id)inSender
{
	[self selectPaneAtIndex:0];
	[self showWindow:nil];
}

-(NSString *)fontSetButtonTitle
{
	return ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) == 0 ? NSLocalizedString(@"Font Set Button Title", @"") : NSLocalizedString(@"Font Reset Button Title", @"");
}

-(void)flagsChanged:(NSEvent *)inEvent
{
	[self willChangeValueForKey:@"fontSetButtonTitle"];
	[self didChangeValueForKey:@"fontSetButtonTitle"];
}

@end

@implementation ProVocPreferences (Languages)

-(void)openLanguageView:(id)inSender
{
	[self selectPaneAtIndex:2];
	[self showWindow:nil];
}

- (NSMutableArray *)languages
{
	static NSMutableArray *languages = nil;
	if (!languages) {
		NSMutableDictionary *prefs = [[NSUserDefaults standardUserDefaults] objectForKey:PVPrefsLanguages];
		languages = prefs[@"Languages"];
		NSEnumerator *enumerator = [languages objectEnumerator];
		languages = [NSMutableArray array];
		NSDictionary *description;
		while (description = [enumerator nextObject]) {
			NSMutableDictionary *mutableDescription = [[description mutableCopy] autorelease];
			if (!mutableDescription[PVPunctuationSensitive])
				mutableDescription[PVPunctuationSensitive] = @YES;
			if (!mutableDescription[PVSpaceSensitive])
				mutableDescription[PVSpaceSensitive] = @YES;
			[languages addObject:mutableDescription];
		}
		[languages retain];
	}
    return languages;
}

-(void)saveLanguagePrefs
{
	id prefs = [[NSUserDefaults standardUserDefaults] objectForKey:PVPrefsLanguages];
	prefs = [[prefs mutableCopy] autorelease];
	prefs[@"Languages"] = [self languages];
	[[NSUserDefaults standardUserDefaults] setObject:prefs forKey:PVPrefsLanguages];
}

- (void)addLanguage:(NSDictionary *)inSettings
{
    [[self languages] addObject:[[inSettings mutableCopy] autorelease]];
	[self saveLanguagePrefs];
    [[NSNotificationCenter defaultCenter] postNotificationName:PVLanguageNamesDidChangeNotification object:nil];
    [mLanguageTableView reloadData];
}

- (IBAction)newLanguage:(id)sender
{
    NSMutableDictionary *description = [NSMutableDictionary dictionary];
    description[@"Name"] = NSLocalizedString(@"New Language", @"");
    description[PVCaseSensitive] = @YES;
    description[PVAccentSensitive] = @YES;
    description[PVPunctuationSensitive] = @YES;
    description[PVSpaceSensitive] = @YES;
	[self addLanguage:description];
	int row = [mLanguageTableView numberOfRows] - 1;
    [mLanguageTableView selectRow:row byExtendingSelection:NO];
	[mLanguageTableView scrollRowToVisible:row];
	[mLanguageTableView editColumn:0 row:row withEvent:nil select:YES];
}

-(IBAction)languageOptions:(id)inSender
{
	[self willChangeValueForKey:@"languageOptionsLanguage"];
	[self didChangeValueForKey:@"languageOptionsLanguage"];
	[self willChangeValueForKey:@"languageOptionsEquivalences"]; /// ---------- I'M HERE !!!! ---------
	[self didChangeValueForKey:@"languageOptionsLanguage"];
}

-(IBAction)confirmLanguageOptions:(id)inSender
{
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if(aTableView == mLanguageTableView)
        return [[self languages] count];
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if(aTableView == mLanguageTableView)
        return [self languages][rowIndex][[aTableColumn identifier]];
    return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if(aTableView == mLanguageTableView) {
        [self languages][rowIndex][[aTableColumn identifier]] = anObject;
        [self saveLanguagePrefs];
        if ([[aTableColumn identifier] isEqual:@"Name"])
            [[NSNotificationCenter defaultCenter] postNotificationName:PVLanguageNamesDidChangeNotification object:nil];
    }
}

-(void)deleteSelectedRowsInTableView:(NSTableView *)inTableView
{
    if(inTableView == mLanguageTableView) {
        NSMutableArray *languagesToDelete = [NSMutableArray array];
        NSEnumerator *enumerator = [mLanguageTableView selectedRowEnumerator];
        NSNumber *row;
        while (row = [enumerator nextObject])
            [languagesToDelete addObject:[self languages][[row intValue]]];
        [[self languages] removeObjectsInArray:languagesToDelete];
        [mLanguageTableView reloadData];
        [self saveLanguagePrefs];
		[[NSNotificationCenter defaultCenter] postNotificationName:PVLanguageNamesDidChangeNotification object:nil];
   }
}

-(NSString *)sourceLanguageCaption
{
	if ([ProVocDocument currentDocument])
		return [[ProVocDocument currentDocument] sourceLanguageCaption];
	else
		return NSLocalizedString(@"Source Language Caption", @"");
}

-(NSString *)targetLanguageCaption
{
	if ([ProVocDocument currentDocument])
		return [[ProVocDocument currentDocument] targetLanguageCaption];
	else
		return NSLocalizedString(@"Target Language Caption", @"");
}

-(void)currentDocumentDidChange
{
	[self willChangeValueForKey:@"sourceLanguageCaption"];
	[self willChangeValueForKey:@"targetLanguageCaption"];
	[self didChangeValueForKey:@"sourceLanguageCaption"];
	[self didChangeValueForKey:@"targetLanguageCaption"];
}

@end

@implementation ProVocPreferences (Panes)

#define PVPreferencesToolbarIdentifier @"PVPreferencesToolbarIdentifier"

-(void)selectPaneAtIndex:(unsigned)inIndex
{
	NSWindow *window = [self window];
	[[window toolbar] setSelectedItemIdentifier:mPaneLabels[inIndex]];

	float factor = 1.0;
	if ([NSApp systemVersion] >= 0x1040)
		factor = [window userSpaceScaleFactor];
	NSView *paneView = mPaneViews[inIndex];
	NSView *view = [window contentView];
	float deltaHeight = [paneView frame].size.height - [view frame].size.height;
	NSRect frameRect = [window frame];
	deltaHeight *= factor;
	frameRect.origin.y -= deltaHeight;
	frameRect.size.height += deltaHeight;
	frameRect.size.width = [paneView frame].size.width * factor;

	[[view subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[window setFrame:frameRect display:YES animate:YES];
	[view addSubview:paneView];
}

-(void)setupToolbar
{
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:PVPreferencesToolbarIdentifier] autorelease];
    
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    [toolbar setDelegate:self];
    
    [[self window] setToolbar:toolbar];
}

-(NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)inToolbar
{
	return mPaneLabels;
}

-(NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)inToolbar
{
	return mPaneLabels;
}

-(NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)inToolbar
{
	return mPaneLabels;
}

-(NSToolbarItem *)toolbar:(NSToolbar *)inToolbar itemForItemIdentifier:(NSString *)inItemIdentifier willBeInsertedIntoToolbar:(BOOL)inWillBeInserted
{
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:inItemIdentifier] autorelease];
    
	[toolbarItem setLabel:inItemIdentifier];
	int index = [mPaneLabels indexOfObject:inItemIdentifier];
	[toolbarItem setImage:[NSImage imageNamed:mPaneImageNames[index]]];
	[toolbarItem setTarget:self];
	[toolbarItem setAction:@selector(selectPreferences:)];
	
	return toolbarItem;
}

-(void)selectPreferences:(id)inSender
{
	[self selectPaneAtIndex:[mPaneLabels indexOfObject:[inSender itemIdentifier]]];
}

@end

@implementation ProVocPreferences (Labels)

-(NSMutableDictionary *)mutableArrayForLabels
{
	id labels = [[NSUserDefaults standardUserDefaults] objectForKey:PVLabels];
	if (YES || ![labels isKindOfClass:[NSMutableArray class]])
		labels = [[labels mutableCopy] autorelease];
	int i;
	for (i = 0; i < [labels count]; i++) {
		id label = labels[i];
		if (YES || ![label isKindOfClass:[NSMutableDictionary class]]) {
			label = [[label mutableCopy] autorelease];
			labels[i] = label;
		}
	}
	return labels;
}

-(void)setValue:(id)inValue forUndefinedKey:(NSString *)inKey
{
	int index = [[inKey substringFromIndex:[inKey length] - 1] intValue] - 1;
	id labels = [self mutableArrayForLabels];
	while ([labels count] <= index)
		[labels addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"?", PVLabelTitle, [NSArchiver archivedDataWithRootObject:[NSColor grayColor]], PVLabelColorData, nil]];
		
	if ([inKey hasPrefix:@"labelTitle"])
		labels[index][PVLabelTitle] = inValue;
	if ([inKey hasPrefix:@"labelColorData"])
		labels[index][PVLabelColorData] = inValue;
	[[NSUserDefaults standardUserDefaults] setObject:labels forKey:PVLabels];
	if ([inKey hasPrefix:@"labelTitle"])
		[ProVocDocument labelTitlesDidChange];
	if ([inKey hasPrefix:@"labelColorData"])
		[ProVocDocument labelColorsDidChange];
}

-(id)valueForUndefinedKey:(NSString *)inKey
{
	int index = [[inKey substringFromIndex:[inKey length] - 1] intValue] - 1;
	NSArray *labels = [[NSUserDefaults standardUserDefaults] objectForKey:PVLabels];
	index = MIN([labels count] - 1, index);
	if ([inKey hasPrefix:@"labelTitle"])
		return labels[index][PVLabelTitle];
	if ([inKey hasPrefix:@"labelColorData"])
		return labels[index][PVLabelColorData];
	
	return nil;//[super valueForUndefinedKey:inKey];
}

-(NSString *)sourceFontCaption
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"sourceFontFamilyName"];
}

-(NSString *)targetFontCaption
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"targetFontFamilyName"];
}

-(NSString *)commentFontCaption
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"commentFontFamilyName"];
}

-(void)observeValueForKeyPath:(NSString *)inKeyPath ofObject:(id)inObject change:(NSDictionary *)inChange context:(void *)inContext
{
	if ([inKeyPath isEqual:@"values.Labels"]) {
		int label;
		for (label = 1; label <= 9; label++) {
			NSString *key = [NSString stringWithFormat:@"labelTitle%i", label];
			[self willChangeValueForKey:key];
			[self didChangeValueForKey:key];
			key = [NSString stringWithFormat:@"labelColorData%i", label];
			[self willChangeValueForKey:key];
			[self didChangeValueForKey:key];
		}
	}
	if ([inKeyPath isEqual:@"values.sourceFontFamilyName"] || [inKeyPath isEqual:@"values.sourceFontSize"]) {
		[self willChangeValueForKey:@"sourceFontCaption"];
		[self didChangeValueForKey:@"sourceFontCaption"];
	}
	if ([inKeyPath isEqual:@"values.targetFontFamilyName"] || [inKeyPath isEqual:@"values.targetFontSize"]) {
		[self willChangeValueForKey:@"targetFontCaption"];
		[self didChangeValueForKey:@"targetFontCaption"];
	}
	if ([inKeyPath isEqual:@"values.commentFontFamilyName"] || [inKeyPath isEqual:@"values.commentFontSize"]) {
		[self willChangeValueForKey:@"commentFontCaption"];
		[self didChangeValueForKey:@"commentFontCaption"];
	}
	if ([inKeyPath isEqual:@"values.PVPrefsRightRatio"])
		[self updateDifficulty:nil];
	if ([inKeyPath isEqual:@"values.reviewLearningFactor"] || [inKeyPath isEqual:@"values.reviewTrainingFactor"])
		[[NSNotificationCenter defaultCenter] postNotificationName:PVReviewFactorDidChangeNotification object:nil];
	if ([inKeyPath isEqual:@"values.StartingPoint"])
		[[ProVocStartingPoint defaultStartingPoint] idle];
}

@end


@implementation ProVocPreferences (Background)

-(BOOL)isBackgroundAvailable
{
	return [ProVocBackground isAvailable];
}

-(BOOL)enableBackground
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:PVEnableBackground];
}

-(void)setEnableBackground:(BOOL)inEnable
{
	[[NSUserDefaults standardUserDefaults] setBool:inEnable forKey:PVEnableBackground];
}

-(NSArray *)backgroundStyleNames
{
	NSMutableArray *names = [NSMutableArray array];
	[names addObjectsFromArray:[ProVocBackgroundStyle availableBackgroundStyleNames]];
	NSString *path = [ProVocBackgroundStyle customBackgroundCompositionPath];
	if (path)
		[names addObject:[[path lastPathComponent] stringByDeletingPathExtension]];
	[names addObject:NSLocalizedString(@"Choose Background", @"")];
	return names;
}

-(int)indexOfSelectedBackgroundStyle
{
	if ([ProVocBackgroundStyle customBackgroundCompositionPath])
		return [[ProVocBackgroundStyle availableBackgroundStyleNames] count];
	else
		return [ProVocBackgroundStyle indexOfCurrentBackgroundStyle];
}

-(void)setIndexOfSelectedBackgroundStyle:(int)inIndex
{
	int n = [[ProVocBackgroundStyle availableBackgroundStyleNames] count];
	if (inIndex < n) {
		[self willChangeValueForKey:@"backgroundStyleNames"];
		[ProVocBackgroundStyle setIndexOfCurrentBackgroundStyle:inIndex];
		[ProVocBackgroundStyle setCustomBackgroundCompositionPath:nil];
		[self didChangeValueForKey:@"backgroundStyleNames"];
	} else if (inIndex == n + 1 || ![ProVocBackgroundStyle customBackgroundCompositionPath])
		[self performSelector:@selector(chooseCustomBackground:) withObject:nil afterDelay:0.0];
}

-(void)chooseCustomBackground:(id)inSender
{
	[self willChangeValueForKey:@"backgroundStyleNames"];
	[self willChangeValueForKey:@"indexOfSelectedBackgroundStyle"];
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setTitle:NSLocalizedString(@"Custom Background Open Panel Title", @"")];
	[openPanel setMessage:NSLocalizedString(@"Custom Background Open Panel Message", @"")];
	[openPanel setPrompt:NSLocalizedString(@"Custom Background Open Panel Prompt", @"")];
	[openPanel setAllowsMultipleSelection:NO];
	if ([openPanel runModalForTypes:@[@"qtz"]] == NSOKButton)
		[ProVocBackgroundStyle setCustomBackgroundCompositionPath:[openPanel filename]];
	[self didChangeValueForKey:@"backgroundStyleNames"];
	[self didChangeValueForKey:@"indexOfSelectedBackgroundStyle"];
}

@end
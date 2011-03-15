//
//  ProVocDocument.m
//  ProVoc
//
//  Created by bovet on Sat Feb 08 2003.
//  Copyright (c) 2003 Arizona Software. All rights reserved.
//

#import "ProVocDocument.h"
#import "ProVocDocument+Lists.h"
#import "ProVocDocument+Presets.h"
#import "ProVocDocument+Slideshow.h"
#import "ProVocDocument+Columns.h"
#import "ProVocDocument+WidgetLog.h"
#import "ProVocWord.h"
#import "ProVocChapter.h"
#import "ProVocData.h"
#import "ProVocData+Undo.h"
#import "ProVocMCQTester.h"
#import "ProVocPrintView.h"
#import "ProVocCardsView.h"
#import "ProVocPreferences.h"
#import "ProVocApplication.h"
#import "ProVocAppDelegate.h"
#import "ProVocActionController.h"
#import "ProVocHistoryView.h"
#import "iPodManager.h"
#import "ProVocInspector.h"
#import "ProVocStartingPoint.h"
#import "ProVocCardController.h"
#import "ProVocTextField.h"

#import "TableViewExtensions.h"
#import "TransformerExtensions.h"
#import "StringExtensions.h"
#import "ScannerExtensions.h"
#import "TextFieldExtensions.h"
#import "WindowExtensions.h"
#import "AppleScriptExtensions.h"
#import "SplitViewExtensions.h"
#import "ArchiverExtensions.h"
#import "ArrayExtensions.h"
#import "ExtendedCell.h"
#import "SpeechSynthesizerExtensions.h"
#import "DateExtensions.h"

#define ProVocInputFontSizeDidChangeNotification @"ProVocInputFontSizeDidChangeNotification"

@interface NSFont (Extern)

-(float)leading;

@end

@interface ProVocDocument (Protected)

-(id)labelsToTest;
-(BOOL)testMCQ;
-(BOOL)allFlagged;
-(NSString *)startTestButtonTitle;
-(void)writingDirectionDidChange;

@end

@implementation ProVocDocument

+(void)initialize
{
	[self setKeys:[NSArray arrayWithObject:@"testDirection"] triggerChangeNotificationsForDependentKey:@"randomTestDirection"];
	NSArray *keys = [NSArray arrayWithObjects:@"testDirection", @"testDirectionProbability", @"sourceLanguage", @"targetLanguage", nil];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"testQuestionDescription"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"testAnswerDescription"];
	[self setKeys:[NSArray arrayWithObject:@"sourceLanguage"] triggerChangeNotificationsForDependentKey:@"sourceLanguageCaption"];
	[self setKeys:[NSArray arrayWithObject:@"sourceLanguage"] triggerChangeNotificationsForDependentKey:@"displayWithSource"];
	[self setKeys:[NSArray arrayWithObject:@"targetLanguage"] triggerChangeNotificationsForDependentKey:@"targetLanguageCaption"];
	[self setKeys:[NSArray arrayWithObject:@"targetLanguage"] triggerChangeNotificationsForDependentKey:@"displayWithTarget"];
	[self setKeys:[NSArray arrayWithObject:@"canResumeTest"] triggerChangeNotificationsForDependentKey:@"startTestButtonTitle"];
	[self setKeys:[NSArray arrayWithObject:@"canResumeTest"] triggerChangeNotificationsForDependentKey:@"canModifyTestParameters"];
	[self setKeys:[NSArray arrayWithObjects:@"labelsToTest", @"testMarked", @"testWordsToReview", nil] triggerChangeNotificationsForDependentKey:@"pageSelectionTitle"];
	[self setKeys:[NSArray arrayWithObjects:@"sourceFontFamilyName", @"sourceFontSize", @"targetFontFamilyName", @"targetFontSize", @"commentFontFamilyName", @"commentFontSize", nil] triggerChangeNotificationsForDependentKey:@"rowHeight"];
	[self setKeys:[NSArray arrayWithObject:@"timer"] triggerChangeNotificationsForDependentKey:@"hideTimerDuration"];
	[self setKeys:[NSArray arrayWithObject:@"voiceIdentifier"] triggerChangeNotificationsForDependentKey:@"selectedVoice"];
	[self setKeys:[NSArray arrayWithObject:@"displayLabels"] triggerChangeNotificationsForDependentKey:@"labelsDisplayed"];
}

-(id)init
{
    if (self = [super init]) {
        mProVocData = [[ProVocData alloc] init];
        
		mNumberOfRetries = [[NSUserDefaults standardUserDefaults] integerForKey:@"PVPrefNumberOfRetry"];
		if (mNumberOfRetries < 1)
			mNumberOfRetries = 3;
		mTestDirectionProbability = 0.5;
		mTestMCQNumber = 4;
		mTestDifficulty = 0.5;
		mShowBacktranslation = YES;
		mInitialSlideshow = YES;
		mAutoPlayMedia = YES;
		mImageMCQ = NO;
		mMediaHideQuestion = 0;
		mTimer = 0;
		mTimerDuration = 5 * 60;
		mUseSpeechSynthesizer = NO;
		mTestOldWords = NO;
		mTestOldNumber = 10;
		mTestOldUnit = 0;
		mTestLimit = NO;
		mTestLimitNumber = 20;
		mTestLimitWhat = 0;
		
		mWords = [[NSMutableArray alloc] initWithCapacity:0];
		mSortedWords = [[NSMutableArray alloc] initWithCapacity:0];
		mVisibleWords = [[NSMutableArray alloc] initWithCapacity:0];
		mSelectedPages = [[NSMutableArray alloc] initWithCapacity:0];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(languageNamesDidChange:)
				name:PVLanguageNamesDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rightRatioDidChange:)
				name:PVRightRatioDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reviewFactorDidChange:)
				name:PVReviewFactorDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iPodDidChange:)
				name:iPodDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputFontSizeDidChange:)
				name:ProVocInputFontSizeDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputTextFieldDidBecomeFirstResponder:)
				name:ProVocTextFieldDidBecomeFirstResponderNotification object:nil];
		
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.PVPrefsUseSynonymSeparator" options:NSKeyValueObservingOptionNew context:@"editCommentString"];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.PVPrefSynonymSeparator" options:NSKeyValueObservingOptionNew context:@"editCommentString"];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.PVPrefsUseCommentsSeparator" options:NSKeyValueObservingOptionNew context:@"editCommentString"];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.PVPrefCommentsSeparator" options:NSKeyValueObservingOptionNew context:@"editCommentString"];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.sourceFontFamilyName" options:NSKeyValueObservingOptionNew context:nil];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.sourceFontSize" options:NSKeyValueObservingOptionNew context:nil];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.sourceTestFontSize" options:NSKeyValueObservingOptionNew context:nil];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.sourceWritingDirection" options:NSKeyValueObservingOptionNew context:nil];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.targetFontFamilyName" options:NSKeyValueObservingOptionNew context:nil];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.targetFontSize" options:NSKeyValueObservingOptionNew context:nil];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.targetTestFontSize" options:NSKeyValueObservingOptionNew context:nil];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.targetWritingDirection" options:NSKeyValueObservingOptionNew context:nil];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.commentFontFamilyName" options:NSKeyValueObservingOptionNew context:nil];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.commentFontSize" options:NSKeyValueObservingOptionNew context:nil];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.commentTestFontSize" options:NSKeyValueObservingOptionNew context:nil];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.commentWritingDirection" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

-(void)dealloc
{
	[[self class] cancelPreviousPerformRequestsWithTarget:self];
	[[NSRunLoop currentRunLoop] cancelPerformSelectorsWithTarget:self];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.PVPrefsUseSynonymSeparator"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.PVPrefSynonymSeparator"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.PVPrefsUseCommentsSeparator"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.PVPrefCommentsSeparator"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.sourceFontFamilyName"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.sourceFontSize"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.sourceTestFontSize"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.sourceWritingDirection"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.targetFontFamilyName"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.targetFontSize"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.targetTestFontSize"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.targetWritingDirection"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.commentFontFamilyName"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.commentFontSize"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.commentTestFontSize"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.commentWritingDirection"];
	
	[mGlobalPreferences release];
    [mProVocData release];
	[mLoadedParameters release];
	
	[mWords release];
	[mSortedWords release];
	[mVisibleWords release];
	[mSelectedPages release];
	[mLabelsToTest release];
	
	[mSearchString release];
	[mTester release];
	
	[mLabels release];
	[mPresets release];
	
	[mHistories release];
	[mSubmissionInfo release];
	[mVoiceIdentifier release];
	[mAllWordTableColumns release];
	
	[mLastWidgetLogModificationDate release];
	[mCurrentWidgetLogHistory release];
	[mCurrentWidgetRepetitions release];

    [super dealloc];
}

-(NSString *)windowNibName
{
    return @"ProVocDocument";
}

-(NSWindow *)window
{
    return mMainWindow;
}

-(void)windowControllerDidLoadNib:(NSWindowController *)inController
{
    [super windowControllerDidLoadNib:inController];
    
	if (!mLoadedParameters) // new document
		[self setMainTab:1];
	else
		if ([mLoadedParameters objectForKey:@"MainTab"])
			[self setMainTab:[[mLoadedParameters objectForKey:@"MainTab"] intValue]];
		else
			[self setMainTab:0];

	[self performSelector:@selector(updateTestOnlyPopUpMenu) withObject:nil afterDelay:0];
	
	if ([mLoadedParameters objectForKey:@"WindowWidth"] && [mLoadedParameters objectForKey:@"WindowHeight"]) {
		NSSize size;
		size.width = [[mLoadedParameters objectForKey:@"WindowWidth"] floatValue];
		size.height = [[mLoadedParameters objectForKey:@"WindowHeight"] floatValue];
		[[self window] setContentSize:size keepTopLeftCorner:YES];
		if ([mLoadedParameters objectForKey:@"WindowLeft"] && [mLoadedParameters objectForKey:@"WindowTop"]) {
			NSPoint topLeftCorner;
			topLeftCorner.x = [[mLoadedParameters objectForKey:@"WindowLeft"] floatValue];
			topLeftCorner.y = [[mLoadedParameters objectForKey:@"WindowTop"] floatValue];
			[inController setShouldCascadeWindows:NO];
			[[self window] setFrameTopLeftPoint:topLeftCorner];
		}
	}
	if (!mGlobalPreferences)
		[self getGlobalPreferencesFromDefaults];

    [[mSearchField cell] setSearchMenuTemplate:mSearchMenu];
	
    [self updateLanguagePopUps];
	[self pagesDidChange];
	id state = [mLoadedParameters objectForKey:@"PageExpandedState"];
	if (state)
		[mPageOutlineView setExpandedState:state];
	id selectedIndexes = [mLoadedParameters objectForKey:@"PageSelectedRowIndexes"];
	if (selectedIndexes) {
		[mPageOutlineView selectRowIndexes:selectedIndexes byExtendingSelection:NO];
		[mPageOutlineView scrollRowToVisible:[selectedIndexes lastIndex]];
		[mPageOutlineView scrollRowToVisible:[selectedIndexes firstIndex]];
	}
			
    ImageAndTextCell *imageAndTextCell = [[[ImageAndTextCell alloc] init] autorelease];
    [imageAndTextCell setEditable:YES];
    [[[mPageOutlineView tableColumns] objectAtIndex:0] setDataCell:imageAndTextCell];

	[self initializeColumns];
	
	[mWordTableView registerForDraggedTypes:[NSArray arrayWithObjects:ProVocSelfWordsType, ProVocWordsType, NSFilenamesPboardType, nil]];
	[mPageOutlineView registerForDraggedTypes:[NSArray arrayWithObjects:ProVocSelfSourcesType, ProVocSourcesType,
																	ProVocSelfWordsType, ProVocWordsType, nil]];
	[mPresetTableView registerForDraggedTypes:[NSArray arrayWithObject:PRESET_PBOARD_TYPE]];

    [self performSelector:@selector(sortWordsByColumn:) withObject:[mWordTableView tableColumnWithIdentifier:@"Number"] afterDelay:0.0];
	
	if ([NSApp systemVersion] < 0x1040)
		[mWordTableView setAutoresizesAllColumnsToFit:YES];
	state = [mLoadedParameters objectForKey:@"WordTableColumnStatesV2"];
	if (!state)
		state = [mLoadedParameters objectForKey:@"WordTableColumnStates"];
	if (state)
		[mWordTableView setTableColumnStates:state];
	else {
		NSTableColumn *column = [mWordTableView tableColumnWithIdentifier:@"NextReview"];
		if (column)
			[mWordTableView removeTableColumn:column];
		[mWordTableView sizeToFit];
	}
	[mLabelTableView setDelegate:self];
	state = [mLoadedParameters objectForKey:@"MainSplitViewState"];
	if (state)
		[mMainSplitView setSplitViewState:state];

	NSBox *presetBoxView = (NSBox *)[mPresetEditView subviewOfClass:[NSBox class]];
	[presetBoxView setFrameSize:[mPresetSettingsView frame].size];
	[[presetBoxView contentView] addSubview:mPresetSettingsView];

	[self setPresetSettings:[mLoadedParameters objectForKey:@"PresetSettings"]];
	[self setEditingPreset:[[mLoadedParameters objectForKey:@"EditingPreset"] boolValue]];
	
	[self willChangeValueForKey:@"canClearHistory"];
	id histories = [mLoadedParameters objectForKey:@"Histories"];
	if (histories) {
		[mHistories release];
		mHistories = [histories mutableCopy];
	}
		
	mSubmissionInfo = [[mLoadedParameters objectForKey:@"SubmissionInfo"] retain];
	
	[self didChangeValueForKey:@"canClearHistory"];
	state = [mLoadedParameters objectForKey:@"HistoryDisplay"];
	if (state)
		[mHistoryView setDisplay:[state intValue]];
	[mHistoryView reloadData];

	[mMainWindow performSelector:@selector(makeFirstResponder:) withObject:mLoadedParameters ? mPresetTableView : [mMainWindow initialFirstResponder] afterDelay:0.0];
	
	[[self undoManager] setLevelsOfUndo:20];
	if ([NSApp systemVersion] < 0x1040)
		[self performSelector:@selector(checkOldFormat:) withObject:nil afterDelay:0.0];
	[self checkWidgetLog];
}

-(void)checkOldFormat:(id)inSender
{
	if ([[[self fileName] pathExtension] isCaseInsensitiveLike:@"ProVoc"])
		NSRunAlertPanel(NSLocalizedString(@"Open Old Format Alert Title", @""), NSLocalizedString(@"Open Old Format Alert Message", @""), nil, nil, nil);
}

-(NSData *)dataRepresentationOfType:(NSString *)inType
{
	if ([self isCurrentDocument])
		[self getGlobalPreferencesFromDefaults];
//    [self setDirty:NO];
	NSSize windowSize = [[self window] frame].size;
	id rootObject = [NSDictionary dictionaryWithObjectsAndKeys:
						mProVocData, @"Data",
						[self parameters], @"Parameters",
						mGlobalPreferences, @"Preferences",
						[NSNumber numberWithFloat:windowSize.width], @"WindowWidth",
						[NSNumber numberWithFloat:windowSize.height], @"WindowHeight",
						[mMainSplitView splitViewState], @"MainSplitViewState",
						[NSNumber numberWithBool:mEditingPreset], @"EditingPreset",
						[[mWordTableView tableColumnStates] objectForKey:@"States"], @"WordTableColumnStates",
						[mPageOutlineView expandedState], @"PageExpandedState",
						[mPageOutlineView selectedRowIndexes], @"PageSelectedRowIndexes",
						[self presetSettings], @"PresetSettings",
						mHistories, @"Histories",
						[NSNumber numberWithInt:[mHistoryView display]], @"HistoryDisplay",
						nil];
    return [NSKeyedArchiver archivedDataWithRootObject:rootObject];
}

-(BOOL)loadDataRepresentation:(NSData *)inData ofType:(NSString *)inType
{
	id loadedObject = [NSKeyedUnarchiver unarchiveObjectWithData:inData];
	if ([loadedObject isKindOfClass:[ProVocData class]])
	    mProVocData = [loadedObject retain];
	else {
		mProVocData = [[loadedObject objectForKey:@"Data"] retain];
		[self setParameters:[loadedObject objectForKey:@"Parameters"]];
		NSMutableDictionary *loadedPrefs = [[[loadedObject objectForKey:@"Preferences"] mutableCopy] autorelease];
		id familyName = [loadedPrefs objectForKey:@"fontFamilyName"];
		if (familyName) {
			[loadedPrefs setObject:familyName forKey:@"sourceFontFamilyName"];
			[loadedPrefs setObject:familyName forKey:@"targetFontFamilyName"];
			[loadedPrefs setObject:familyName forKey:@"commentFontFamilyName"];
		}

		id fontSize = [loadedPrefs objectForKey:@"fontSize"];
		if (fontSize) {
			[loadedPrefs setObject:fontSize forKey:@"sourceFontSize"];
			[loadedPrefs setObject:fontSize forKey:@"targetFontSize"];
		}

		fontSize = [loadedPrefs objectForKey:@"questionFontSize"];
		if (fontSize) {
			[loadedPrefs setObject:fontSize forKey:@"sourceTestFontSize"];
			[loadedPrefs setObject:fontSize forKey:@"targetTestFontSize"];
		}

		fontSize = [loadedPrefs objectForKey:@"commentFontSize"];
		if (fontSize) {
			[loadedPrefs setObject:fontSize forKey:@"commentTestFontSize"];
			[loadedPrefs removeObjectForKey:@"commentFontSize"];
		}

		[self getGlobalPreferencesFromDefaults];
		[mGlobalPreferences setValuesForKeysWithDictionary:loadedPrefs];
		mLoadedParameters = [loadedObject retain];
	}
    return YES;
}

-(BOOL)writeToFile:(NSString *)inFullDocumentPath ofType:(NSString *)inDocType originalFile:(NSString *)inFullOriginalDocumentPath
	saveOperation:(NSSaveOperationType)inSaveOperationType
{
	BOOL ok = NO;
	NS_DURING
		if ([inDocType isEqual:@"ProVocDocumentPackage"])
			[self moveUsedMediaFromFile:inFullOriginalDocumentPath toTemporaryFolderForSaveOperation:inSaveOperationType];
		ok = [super writeToFile:inFullDocumentPath ofType:inDocType originalFile:inFullOriginalDocumentPath saveOperation:inSaveOperationType];
	NS_HANDLER
		ok = NO;
		NSLog(@"*** Exception raised during %@: %@", NSStringFromSelector(_cmd), localException);
	NS_ENDHANDLER
	return ok;
}

-(void)autosaveDocumentWithDelegate:(id)inDelegate didAutosaveSelector:(SEL)inDidAutosaveSelector contextInfo:(void *)inContextInfo
{
	if ([[self fileType] isEqual:@"ProVocDocumentPackage"]) {
		mAutosaving = YES;
		[super autosaveDocumentWithDelegate:inDelegate didAutosaveSelector:inDidAutosaveSelector contextInfo:inContextInfo];
		mAutosaving = NO;
	}
}

-(BOOL)writeToFile:(NSString *)inFileName ofType:(NSString *)inDocType
{
	if ([inDocType isEqual:@"ProVocDocumentPackage"]) {
		BOOL ok = [super writeToFile:inFileName ofType:inDocType];
		[self moveUsedMediaIntoBundle:ok ? inFileName : nil];
		[self reindexWordsInFile];
		return ok;
	} else {
		NSRunAlertPanel(NSLocalizedString(@"Save As New Format Alert Title", @""), NSLocalizedString(@"Save As New Format Alert Message", @""), nil, nil, nil);
		[self saveDocumentAs:nil];
		return YES;
	}
}

-(NSArray *)usedLanguageSettings
{
	NSMutableArray *usedSettings = [NSMutableArray array];
	NSArray *usedLanguageNames = [NSArray arrayWithObjects:[self sourceLanguage], [self targetLanguage], nil];
	NSDictionary *languages = [[NSUserDefaults standardUserDefaults] objectForKey:PVPrefsLanguages];
    NSEnumerator *enumerator = [[languages objectForKey:@"Languages"] objectEnumerator];
    NSDictionary *description;
    while (description = [enumerator nextObject])
		if ([usedLanguageNames containsObject:[description objectForKey:@"Name"]])
			[usedSettings addObject:description];
	return usedSettings;
}

-(NSFileWrapper *)fileWrapperRepresentationOfType:(NSString *)inType
{
	NSFileWrapper *fileWrapper = nil;
	
	NS_DURING
		if ([self isCurrentDocument])
			[self getGlobalPreferencesFromDefaults];
		[self finalCheckWidgetLog];
		
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:mProVocData];

		NSRect windowFrame = [[self window] frame];
		NSSize windowSize = windowFrame.size;
		NSPoint windowTopLeftCorner = NSMakePoint(NSMinX(windowFrame), NSMaxY(windowFrame));
		id wordColumnStates = [mWordTableView tableColumnStates];
		id settings = [NSDictionary dictionaryWithObjectsAndKeys:
							[self parameters], @"Parameters",
							mGlobalPreferences, @"Preferences",
							[NSNumber numberWithFloat:windowSize.width], @"WindowWidth",
							[NSNumber numberWithFloat:windowSize.height], @"WindowHeight",
							[NSNumber numberWithFloat:windowTopLeftCorner.x], @"WindowLeft",
							[NSNumber numberWithFloat:windowTopLeftCorner.y], @"WindowTop",
							[NSNumber numberWithInt:mMainTab], @"MainTab",
							[mMainSplitView splitViewState], @"MainSplitViewState",
							[NSNumber numberWithBool:mEditingPreset], @"EditingPreset",
							wordColumnStates, @"WordTableColumnStatesV2",
							[wordColumnStates objectForKey:@"States"], @"WordTableColumnStates",
							[mPageOutlineView expandedState], @"PageExpandedState",
							[mPageOutlineView selectedRowIndexes], @"PageSelectedRowIndexes",
							[self presetSettings], @"PresetSettings",
							mHistories, @"Histories",
							[NSNumber numberWithInt:[mHistoryView display]], @"HistoryDisplay",
							[self usedLanguageSettings], @"UsedLanguageSettings",
							mSubmissionInfo, @"SubmissionInfo", // may be nil
							nil];
		NSData *settingsData = [NSKeyedArchiver archivedDataWithRootObject:settings];
		id publicSettings = [NSDictionary dictionaryWithObjectsAndKeys:
									[self parameters], @"Parameters",
									mGlobalPreferences, @"Preferences",
									[self usedLanguageSettings], @"Languages",
									mSubmissionInfo, @"SubmissionInfo", // may be nil
									nil];
		NSData *publicSettingsData = [NSKeyedArchiver archivedDataWithRootObject:publicSettings];

		NSMutableDictionary *fileWrappers = [NSMutableDictionary dictionary];
		[fileWrappers setObject:[[[NSFileWrapper alloc] initRegularFileWithContents:data] autorelease] forKey:@"Data"];
		[fileWrappers setObject:[[[NSFileWrapper alloc] initRegularFileWithContents:settingsData] autorelease] forKey:@"Settings"];
		[fileWrappers setObject:[[[NSFileWrapper alloc] initRegularFileWithContents:publicSettingsData] autorelease] forKey:@"PublicSettings"];
		fileWrapper = [[[NSFileWrapper alloc] initDirectoryWithFileWrappers:fileWrappers] autorelease];
	NS_HANDLER
	NS_ENDHANDLER
	
//	if (fileWrapper)
//	    [self setDirty:NO];
	return fileWrapper;
}

-(void)setUsedLanguageSettings:(NSArray *)inSettings
{
	NSMutableArray *existingLanguageNames = [NSMutableArray array];
	NSDictionary *languages = [[NSUserDefaults standardUserDefaults] objectForKey:PVPrefsLanguages];
    NSEnumerator *enumerator = [[languages objectForKey:@"Languages"] objectEnumerator];
    NSDictionary *description;
    while (description = [enumerator nextObject])
		[existingLanguageNames addObject:[description objectForKey:@"Name"]];

	enumerator = [inSettings objectEnumerator];
	while (description = [enumerator nextObject])
		if (![existingLanguageNames containsObject:[description objectForKey:@"Name"]])
			[[ProVocPreferences sharedPreferences] addLanguage:description];
}

-(BOOL)loadFileWrapperRepresentation:(NSFileWrapper *)inFileWrapper ofType:(NSString *)inType
{
	[mProVocData release];
	mProVocData = nil;
	[mLoadedParameters release];
	mLoadedParameters = nil;
	
	BOOL ok = YES;
	NS_DURING
		if ([inFileWrapper isDirectory]) {
			NSDictionary *wrappers = [inFileWrapper fileWrappers];
			NSData *data = [[wrappers objectForKey:@"Data"] regularFileContents];
			NSData *settingsData = [[wrappers objectForKey:@"Settings"] regularFileContents];
			
			mProVocData = [[NSKeyedUnarchiver unarchiveObjectWithData:data] retain];
			id settings = [NSKeyedUnarchiver unarchiveObjectWithData:settingsData];
			[self setUsedLanguageSettings:[settings objectForKey:@"UsedLanguageSettings"]];
			[self setParameters:[settings objectForKey:@"Parameters"]];
			[self getDefaultGlobalPreferencesFromDefaults];
			[mGlobalPreferences setValuesForKeysWithDictionary:[settings objectForKey:@"Preferences"]];
			mLoadedParameters = [settings retain];
		} else
			ok = [super loadFileWrapperRepresentation:inFileWrapper ofType:inType];
	NS_HANDLER
		ok = NO;
	NS_ENDHANDLER
		
	if (ok) {
		[self reindexWordsInFile];
		
		[mWordTableView reloadData];
		[mPageOutlineView reloadData];
		
		[self rightRatioDidChange:nil];
		[self updateLanguagePopUps];
		[self pagesDidChange];
		[self languagesDidChange];
	}
	return ok;
}

-(NSString *)displayName
{
	if ([self fileName])
		return [[[self fileName] lastPathComponent] stringByDeletingPathExtension];
	else
		return [super displayName];
}

-(BOOL)displayPages
{
	return mDisplayPages;
}

-(void)setDisplayPages:(BOOL)inDisplay
{
	mDisplayPages = inDisplay;
}

-(int)mainTab
{
	return mMainTab;
}

-(void)setMainTab:(int)inTab
{
	if (mMainTab != inTab) {
		[self willChangeValueForKey:@"mainTab"];
		mMainTab = inTab;
		[self didChangeValueForKey:@"mainTab"];
		[self selectedWordsDidChange:nil];
	}
	[[ProVocInspector sharedInspector] setPreferredDisplayState:mMainTab == 1];
}

-(BOOL)editingPreset
{
	return mEditingPreset;
}

-(void)animatePresetViewToFrame:(NSRect)inDestinationFrame
{
	NSRect sourceFrame = [mPresetView frame];
	NSRect editFrame = [mPresetEditView frame];
	NSTimeInterval begin = [NSDate timeIntervalSinceReferenceDate];
	for (;;) {
		float t = MIN(1.0, ([NSDate timeIntervalSinceReferenceDate] - begin) / 0.25);
		t = t < 0.5 ? 2.0 * t * t : 1.0 - 2.0 * (1.0 - t) * (1.0 - t);
		
		NSRect frame = sourceFrame;
		frame.size.width = t * inDestinationFrame.size.width + (1.0 - t) * sourceFrame.size.width;
		[mPresetView setFrame:frame];
		
		NSRect edit = editFrame;
		edit.origin.x = NSMaxX(frame) + 9;
		edit.size.width = NSMaxX(editFrame) - edit.origin.x;
		[mPresetEditView setFrame:edit];
		
		[[mPresetView superview] display];
		if (t >= 1.0)
			break;
	}
	[mPresetEditView setFrame:editFrame];
}

-(void)setEditingPreset:(BOOL)inEdit
{
	if (inEdit && mEditingPreset != inEdit) {
		[self willChangeValueForKey:@"editingPreset"];
		mEditingPreset = inEdit;
		[self didChangeValueForKey:@"editingPreset"];
	}
	
	NSRect frame = [mPresetView frame];
	if (inEdit)
		frame.size.width = NSMinX([mPresetEditView frame]) - 9 - NSMinX(frame);
	else
		frame.size.width = NSMaxX([mPresetEditView frame]) - NSMinX(frame);
	if ([mMainWindow isVisible])
		[self animatePresetViewToFrame:frame];
	[mPresetView setFrame:frame];
	[[mPresetView superview] setNeedsDisplay:YES];

	if (!inEdit && mEditingPreset != inEdit) {
		[self willChangeValueForKey:@"editingPreset"];
		mEditingPreset = inEdit;
		[self didChangeValueForKey:@"editingPreset"];
	}
}

-(BOOL)isEditing
{
	return [self mainTab] == 1;
}

-(BOOL)validateMenuItem:(NSMenuItem *)inItem
{
	BOOL flag;
	if ([self validate:&flag columnMenuItem:inItem])
		return flag;

	SEL action = [inItem action];
	if (action == @selector(selectView:))
		[inItem setState:[inItem tag] == [self mainTab] ? NSOnState : NSOffState];
	if (action == @selector(startTest:))
		[inItem setTitle:[self startTestButtonTitle]];
	if (action == @selector(swapSourceAndTarget:)) {
		NSString *title = NSLocalizedString(@"Swap %@ and %@", @"");
		NSString *source = [self sourceLanguage];
		NSString *target = [self targetLanguage];
		NSString *comment = NSLocalizedString(@"Comment Column Identifier", @"");
		switch ([inItem tag]) {
			case 0:
				title = [NSString stringWithFormat:title, source, target];
				break;
			case 1:
				title = [NSString stringWithFormat:title, source, comment];
				break;
			case 2:
				title = [NSString stringWithFormat:title, target, comment];
				break;
		}
		[inItem setTitle:title];
	}
	if (action == @selector(recordSound:)) {
		[inItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Record Sound for Language %@", @""), [inItem tag] == 0 ? [self sourceLanguage] : [self targetLanguage]]];
		return [self isEditing];
	}
	if (action == @selector(flag:))
		[inItem setTitle:[self allFlagged] ? NSLocalizedString(@"Unflag Selected Words", @"") : NSLocalizedString(@"Flag Selected Words", @"")];
	if (action == @selector(swapSourceAndTarget:) || action == @selector(resetDifficulty:) || action == @selector(flag:) || action == @selector(unflag:) || action == @selector(viewOptions:))
		return [self isEditing];
	if (action == @selector(modifyDifficulty:))
		return [self isEditing] && [[self selectedWords] count] > 0;
	if (action == @selector(setLabel:)) {
		int label = [inItem tag];
		[inItem setImage:[self imageForLabel:label]];
		[inItem setTitle:[self stringForLabel:label]];
		return [self isEditing];
	}
	if (action == @selector(revealSelectedWordsInPages:))
		return [self isEditing] && [[self selectedWords] count] > 0;
	if (action == @selector(setSearchCategory:))
		[inItem setState:[[NSUserDefaults standardUserDefaults] boolForKey:[self searchCategoryForTag:[inItem tag]]] ? NSOnState : NSOffState];
	if (action == @selector(submitDocument:))
		[inItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Submit %@", @""), [self displayName]]];
	if (action == @selector(deletePage:))
		return [[[mProVocData rootChapter] children] count] > 0;
	if (action == @selector(removePreset:))
		return [self canRemovePreset];
	return YES;
}

-(void)setDirty:(BOOL)inFlag
{
	[NSException raise:@"Deprecated" format:@"-[%@ %@] deprecated!", NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
//    [self updateChangeCount:inFlag ? NSChangeDone : NSChangeCleared];
}

-(void)selectedWordsDidChange:(id)inSender
{
	NSArray *words = nil;
	if (mMainTab == 1)
		words = [self selectedWords];
	[[ProVocInspector sharedInspector] setSelectedWords:words];
}

-(void)documentParameterDidChange:(id)inSender
{
	[[ProVocInspector sharedInspector] documentParameterDidChange:self];
}

-(void)selectedWordParameterDidChange:(id)inSender
{
	[mWordTableView reloadData];
	[[ProVocInspector sharedInspector] selectedWordParameterDidChange:inSender];
}

-(void)inputTextFieldDidBecomeFirstResponder:(NSNotification *)inNotification
{
	NSWindow *window = [[inNotification object] window];
	if (window == mMainWindow)
		[mWordTableView deselectAll:nil];
}

@end

@implementation ProVocDocument (Preferences)

-(NSArray *)globalPreferenceKeys
{
	static NSArray *keys = nil;
	if (!keys)
		keys = [[NSArray alloc] initWithObjects:PVPrefsUseSynonymSeparator, PVPrefSynonymSeparator, PVPrefTestSynonymsSeparately,
												PVPrefsUseCommentsSeparator, PVPrefCommentsSeparator,
												PVPrefsRightRatio, PVLabels,
												@"sourceFontFamilyName", @"sourceFontSize", @"sourceTestFontSize", @"sourceWritingDirection",
												@"targetFontFamilyName", @"targetFontSize", @"targetTestFontSize", @"targetWritingDirection",
												@"commentFontFamilyName", @"commentFontSize", @"commentTestFontSize", @"commentWritingDirection",
												PVLearnedConsecutiveRepetitions, PVLearnedDistractInterval, PVReviewLearningFactor, PVReviewTrainingFactor,
												nil];
	return keys;
}

-(NSDictionary *)globalDefaults
{
	static NSDictionary *dictionary = nil;
	if (!dictionary)
		dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
												[NSNumber numberWithInt:NSWritingDirectionLeftToRight], @"sourceWritingDirection",
												[NSNumber numberWithInt:NSWritingDirectionLeftToRight], @"targetWritingDirection",
												[NSNumber numberWithInt:NSWritingDirectionLeftToRight], @"commentWritingDirection",
												nil];
	return dictionary;
}

-(void)getGlobalPreferencesFromDefaults:(BOOL)inAll
{
	if (!mGlobalPreferences)
		mGlobalPreferences = [[NSMutableDictionary alloc] initWithCapacity:0];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSEnumerator *enumerator = [[self globalPreferenceKeys] objectEnumerator];
	id key;
	while (key = [enumerator nextObject]) {
		id value = [defaults objectForKey:key];
		if (value && (inAll || ![[self globalDefaults] objectForKey:key]))
			[mGlobalPreferences setObject:value forKey:key];
	}
}

-(void)getGlobalPreferencesFromDefaults
{
	[self getGlobalPreferencesFromDefaults:YES];
}

-(void)getDefaultGlobalPreferencesFromDefaults
{
	[self getGlobalPreferencesFromDefaults:NO];
}

-(void)setGlobalPreferencesToDefaults
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *globalDefaults = [self globalDefaults];
	NSEnumerator *enumerator = [globalDefaults keyEnumerator];
	id key;
	while (key = [enumerator nextObject])
		if (![mGlobalPreferences objectForKey:key])
			[defaults setObject:[globalDefaults objectForKey:key] forKey:key];
	
	enumerator = [mGlobalPreferences keyEnumerator];
	while (key = [enumerator nextObject])
		[defaults setObject:[mGlobalPreferences objectForKey:key] forKey:key];
	[[NSUserDefaults standardUserDefaults] upgrade];
}

-(NSArray *)parameterKeys
{
	static NSArray *keys = nil;
	if (!keys)
		keys = [[NSArray alloc] initWithObjects:@"numberOfRetries", @"testDirection", @"testDirectionProbability", @"testKind", @"testMarked", @"testWordsToReview",
									@"labelsToTest", @"lateComments", @"testMCQ", @"testMCQNumber", @"delayedMCQ", @"testDifficulty",
									@"showBacktranslation", @"displayLabels", @"colorWindowWithLabel", @"displayLabelText",
									@"autoPlayMedia", @"imageMCQ", @"mediaHideQuestion", @"initialSlideshow",
									@"timer", @"timerDuration", @"useSpeechSynthesizer", @"voiceIdentifier",
									@"testOldWords", @"testOldNumber", @"testOldUnit", 
									@"testLimit", @"testLimitNumber", @"testLimitWhat",
									@"dontShuffleWords",
									nil];
	return keys;
}

-(NSDictionary *)parameters
{
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	NSEnumerator *enumerator = [[self parameterKeys] objectEnumerator];
	id key;
	while (key = [enumerator nextObject]) {
		id value = [self valueForKey:key];
		if (value)
			[parameters setObject:value forKey:key];
	}
	return parameters;
}

-(void)setParameters:(NSDictionary *)inParameters
{
	NSArray *keysWithZeroDefault = [NSArray arrayWithObjects:@"displayLabels", @"colorWindowWithLabel", @"displayLabelText", @"testOldWords", @"testLimit", @"testWordsToReview", @"dontShuffleWords", nil];
	NSEnumerator *enumerator = [[self parameterKeys] objectEnumerator];
	id key;
	while (key = [enumerator nextObject]) {
		id value = [inParameters objectForKey:key];
		if (!value && [keysWithZeroDefault containsObject:key])
			value = [NSNumber numberWithBool:NO];
		if (value)
			[self setValue:value forKey:key];
	}
}

@end

@implementation ProVocDocument (Current)

static ProVocDocument *sCurrentDocument = nil;

+(void)setCurrentDocument:(ProVocDocument *)inDocument
{
	if (sCurrentDocument != inDocument) {
		[sCurrentDocument getGlobalPreferencesFromDefaults];
		[sCurrentDocument release];
		sCurrentDocument = [inDocument retain];
		[sCurrentDocument setGlobalPreferencesToDefaults];
		[[ProVocInspector sharedInspector] setDocument:sCurrentDocument];
		[sCurrentDocument setMainTab:[sCurrentDocument mainTab]];
		[[ProVocPreferences sharedPreferences] currentDocumentDidChange];
		[sCurrentDocument selectedWordsDidChange:nil];
		if (sCurrentDocument)
			[NSSpeechSynthesizer setDefaultVoice:[sCurrentDocument valueForKey:@"voiceIdentifier"]];
	}
}

-(void)windowDidBecomeMain:(NSNotification *)inNotification
{
	[[self class] setCurrentDocument:self];
	[self checkWidgetLog];
	[[ProVocStartingPoint defaultStartingPoint] idle];
}

-(void)windowWillClose:(NSNotification *)inNotification
{
	[[self class] setCurrentDocument:nil];
	[[ProVocStartingPoint defaultStartingPoint] performSelector:@selector(idle) withObject:nil afterDelay:0.0];
}

+(ProVocDocument *)currentDocument
{
	return sCurrentDocument;
}

-(BOOL)isCurrentDocument
{
	return self == sCurrentDocument;
}

@end

@implementation ProVocDocument (Actions)

-(void)addSource:(ProVocSource *)inSource
{
	[self willChangeData];
	ProVocChapter *chapter = [mProVocData rootChapter];
	int index = -1;
	int row = [[mPageOutlineView selectedRowIndexes] lastIndex];
	id selection = [mPageOutlineView itemAtRow:row];
	if (selection) {
		if ([selection isKindOfClass:[ProVocChapter class]])
			chapter = selection;
		else {
			chapter = (ProVocChapter *)[selection parent];
			index = [[chapter children] indexOfObjectIdenticalTo:selection] + 1;
		}
		if ([inSource isKindOfClass:[ProVocChapter class]] || ![mPageOutlineView isItemExpanded:chapter]) {
			id parent = (ProVocChapter *)[chapter parent];
			if (!parent) {
				chapter = [mProVocData rootChapter];
				index = -1;
			} else {
				index = [[parent children] indexOfObjectIdenticalTo:chapter] + 1;
				chapter = parent;
			}
		}
	}
	if (index < 0)
		index = [[chapter children] count];
	
	[chapter insertChild:inSource atIndex:index];
	[self pagesDidChange];
	[mPageOutlineView expandItem:inSource];
	row = [mPageOutlineView rowForItem:inSource];
	[mPageOutlineView selectRow:row byExtendingSelection:NO];
	[mPageOutlineView scrollRowToVisible:row];
	[self didChangeData];
	[self setMainTab:1];
}

-(void)requestNewName:(NSString *)inPrompt defaultName:(NSString *)inDefaultName callbackSelector:(SEL)inCallbackSelector
{
	mInputPanelCallbackSelector = inCallbackSelector;
    [self openInputPanel:inPrompt defaultValue:inDefaultName];
}

-(IBAction)newPage:(id)inSender
{
	NSArray *pages = [self selectedPages];
	NSString *defaultName = nil;
	if ([pages count] == 1) {
		id name = [[[[pages lastObject] title] mutableCopy] autorelease];
		NSMutableString *suffix = [NSMutableString string];
		while ([name length] > 0 && [[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[name characterAtIndex:[name length] - 1]]) {
			[suffix insertString:[name substringFromIndex:[name length] - 1] atIndex:0];
			[name deleteCharactersInRange:NSMakeRange([name length] - 1, 1)];
		}
		while ([name length] > 1 && [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[name characterAtIndex:[name length] - 1]] && [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[name characterAtIndex:[name length] - 2]])
			[name deleteCharactersInRange:NSMakeRange([name length] - 1, 1)];
		int index = [suffix intValue] + 1;
		if ([suffix length] == 0) {
			index = 2;
			while ([name length] > 0 && [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[name characterAtIndex:[name length] - 1]])
				[name deleteCharactersInRange:NSMakeRange([name length] - 1, 1)];
			if ([name length] > 0)
				name = [name stringByAppendingString:@" "];
		}
		for (;;) {
			defaultName = [NSString stringWithFormat:@"%@%i", name, index];
			BOOL keepOn = NO;
			NSEnumerator *enumerator = [[self allPages] objectEnumerator];
			ProVocPage *page;
			while (page = [enumerator nextObject])
				if ([[page title] isEqualToString:defaultName]) {
					keepOn = YES;
					break;
				}
			if (!keepOn)
				break;
			index++;
		}
	}
	if (!defaultName)
		defaultName = [NSString stringWithFormat:NSLocalizedString(@"Page Name %i", @""), [[self allPages] count] + 1];
	[self requestNewName:NSLocalizedString(@"Enter the name of the new page:", @"")
			defaultName:defaultName
			callbackSelector:@selector(createPageWithTitle:)];
}

-(void)createPageWithTitle:(NSString *)inTitle
{
	ProVocPage *page = [[[ProVocPage alloc] init] autorelease];
	[page setTitle:inTitle];
	[self addSource:page];
}

-(IBAction)newChapter:(id)inSender
{
	static int n = 1;
	[self requestNewName:NSLocalizedString(@"Enter the name of the new chapter:", @"")
			defaultName:[NSString stringWithFormat:NSLocalizedString(@"Chapter Name %i", @""), n++]
			callbackSelector:@selector(createChapterWithTitle:)];
}

-(void)createChapterWithTitle:(NSString *)inTitle
{
	ProVocChapter *chapter = [[[ProVocChapter alloc] init] autorelease];
	[chapter setTitle:inTitle];
	[self addSource:chapter];
}

-(IBAction)deletePage:(id)inSender
{
	[self willChangeData];
	[mWordTableView abortEditing];
	NSEnumerator *enumerator = [[self selectedSourceAncestors] objectEnumerator];
	id source;
	while (source = [enumerator nextObject])
		[(ProVocChapter *)[source parent] removeChild:source];
	[self pagesDidChange];
	[self didChangeData];
}

static int sNewWordLabel = 0;

-(IBAction)addNewWord:(id)inSender
{
	if ([[mTargetTextField stringValue] length] == 0) {
		[mMainWindow performSelector:@selector(makeFirstResponder:) withObject:mTargetTextField afterDelay:0.0];
		return;
	}
	
	ProVocPage *currentPage = [self currentPage];
	[self willChangeSource:currentPage];
    ProVocWord *word = [[[ProVocWord alloc] init] autorelease];
    [word setSourceWord:[mSourceTextField stringValue]];
    [word setTargetWord:[mTargetTextField stringValue]];
	if ([[mCommentTextField stringValue] length] > 0)
	    [word setComment:[mCommentTextField stringValue]];
    
	[word setLabel:sNewWordLabel];
    [currentPage addWord:word];
	[self wordsDidChange];
    
	unsigned rowIndex = [mVisibleWords indexOfObject:word];
	if (rowIndex != NSNotFound) {
//		[mWordTableView selectRow:rowIndex byExtendingSelection:NO];
		[mWordTableView scrollRowToVisible:rowIndex];
	}
	[self selectedWordsDidChange:nil];

    [mSourceTextField setStringValue:@""];
    [mTargetTextField setStringValue:@""];
	[mCommentTextField setStringValue:@""];

	[mMainWindow performSelector:@selector(makeFirstResponder:) withObject:mSourceTextField afterDelay:0.0];

	[self didChangeSource:currentPage];
}

-(IBAction)search:(id)inSender
{
	mShowDoubles = NO;
	[mSearchString release];
	mSearchString = [[inSender stringValue] retain];
	[self keepSelectedWords];
	[self visibleWordsDidChange];
}

-(NSString *)searchCategoryForTag:(int)inTag
{
	switch (inTag) {
		case 0:
			return PVSearchSources;
		case 1:
			return PVSearchTargets;
		case 2:
			return PVSearchComments;
	}
	return nil;
}

-(IBAction)setSearchCategory:(id)inSender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	id category = [self searchCategoryForTag:[inSender tag]];
	[defaults setBool:![defaults boolForKey:category] forKey:category];
	[self visibleWordsDidChange];
}

-(void)markSelectedWordsWithMark:(int)inMark
{
	[self willChangeData];
    NSEnumerator *enumerator = [[self selectedWords] objectEnumerator];
    ProVocWord *word;
    while (word = [enumerator nextObject])
        [word setMark:inMark];
	[mWordTableView reloadData];
	[self didChangeData];
}

-(BOOL)allFlagged
{
	NSArray *words = [self selectedWords];
	if ([words count] == 0)
		return NO;
    NSEnumerator *enumerator = [words objectEnumerator];
    ProVocWord *word;
    while (word = [enumerator nextObject])
        if ([word mark] == 0)
			return NO;
	return YES;
}

-(IBAction)flag:(id)inSender
{
    [self markSelectedWordsWithMark:[self allFlagged] ? 0 : 1];
}

-(IBAction)unflag:(id)inSender
{
    [self markSelectedWordsWithMark:0];
}

-(IBAction)setLabel:(id)inSender
{
	int label = [inSender tag];
	NSArray *words = [self selectedWords];
	if ([words count] > 0) {
		[self willChangeData];
		NSEnumerator *enumerator = [words objectEnumerator];
		ProVocWord *word;
		while (word = [enumerator nextObject])
			[word setLabel:label];
		[mWordTableView reloadData];
		[self didChangeData];
	} else
		sNewWordLabel = label;
}

-(IBAction)find:(id)inSender
{
	[self setMainTab:1];
	[mMainWindow makeFirstResponder:mSearchField];
}

-(BOOL)containsWordMatchingSearchString:(NSString *)inSearchString
{
	NSString *searchString = [inSearchString stringByRemovingAccents];
	NSEnumerator *enumerator = [[self allWords] objectEnumerator];
	ProVocWord *word;
	while (word = [enumerator nextObject])
		if ([self doesWord:word containString:searchString])
			return YES;
	return NO;
}

-(void)setSpotlightSearch:(NSString *)inSearchString
{
	const int categories = 3;
	int category;
	BOOL searchCategory[categories];
	for (category = 0; category < categories; category++) {
		NSString *key = [self searchCategoryForTag:category];
		searchCategory[category] = [[NSUserDefaults standardUserDefaults] boolForKey:key];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:key];
	}
	
	if ([self containsWordMatchingSearchString:inSearchString]) {
		[NSObject cancelPreviousPerformRequestsWithTarget:mMainWindow selector:@selector(makeFirstResponder:) object:mPresetTableView];
		[mPageOutlineView selectAll:nil];
		[mSearchField setStringValue:inSearchString];
		
		[self search:mSearchField];
		[self setMainTab:1];
		[mMainWindow makeFirstResponder:mSearchField];
	}

	for (category = 0; category < categories; category++) {
		NSString *key = [self searchCategoryForTag:category];
		[[NSUserDefaults standardUserDefaults] setBool:searchCategory[category] forKey:key];
	}
}

-(void)cancelFindDoubles:(id)inSender
{
	[self cancelDoubleWordSearch];
}

-(void)doubleWordSearchProgress:(NSNumber *)inProgress
{
	[mActionController performSelectorOnMainThread:@selector(setProgress:) withObject:inProgress waitUntilDone:NO];
}

-(void)findDoublesThread:(NSArray *)inWords
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	id doubles = [self doubleWordsIn:inWords progressDelegate:self];
	if (doubles)
		[self performSelectorOnMainThread:@selector(foundDoubles:) withObject:doubles waitUntilDone:YES];
	[pool release];
}

-(void)foundDoubles:(id)inDoubles
{
	[mActionController finish];
	[mActionController release];
	mActionController = nil;

	if ([inDoubles count] == 0)
		NSRunAlertPanel(NSLocalizedString(@"No Doubles Found Title", @""), NSLocalizedString(@"No Doubles Found Message", @""), nil, nil, nil);
	else {
		[mWords makeObjectsPerformSelector:@selector(setDouble:) withObject:[NSNumber numberWithBool:NO]];
		[inDoubles makeObjectsPerformSelector:@selector(setDouble:) withObject:[NSNumber numberWithBool:YES]];
		mShowDoubles = YES;
		[self sortedWordsDidChange];
/*		NSEnumerator *enumerator = [inDoubles objectEnumerator];
		ProVocWord *word;
		BOOL extend = NO;
		int row = 0;
		while (word = [enumerator nextObject]) {
			[mWordTableView selectRow:row = [mVisibleWords indexOfObjectIdenticalTo:word] byExtendingSelection:extend];
			extend = YES;
		}
		[mWordTableView scrollRowToVisible:row];
		[mMainWindow makeFirstResponder:mWordTableView]; */
	}
}

-(IBAction)findDoubles:(id)inSender
{
	[self setMainTab:1];
	if (![self showingAllWords])
		[self showAllWords];
	mActionController = [[ProVocActionController actionControllerWithTitle:NSLocalizedString(@"Finding Doubles Action Title", @"") modalWindow:mMainWindow delegate:self cancelSelector:@selector(cancelFindDoubles:)] retain];
	[NSThread detachNewThreadSelector:@selector(findDoublesThread:) toTarget:self withObject:mVisibleWords];
}

-(NSArray *)selectedOrAllWords
{
	NSArray *words = [self selectedWords];
	if ([words count] == 0)
		words = mWords;
	return words;
}

-(IBAction)swapSourceAndTarget:(id)inSender
{
	[self willChangeData];
	[mWordTableView abortEditing];
    [[self selectedOrAllWords] makeObjectsPerformSelector:@selector(swapSourceAndTarget:) withObject:inSender];
	[self visibleWordsDidChange];
	[self didChangeData];
}

-(IBAction)resetDifficulty:(id)inSender
{
	[self willChangeData];
	[[self selectedOrAllWords] makeObjectsPerformSelector:@selector(reset)];
	[self visibleWordsDidChange];
	[self didChangeData];
}

-(IBAction)modifyDifficulty:(id)inSender
{
	SEL selector;
	switch ([inSender tag]) {
		case 0:
			selector = @selector(resetDifficulty);
			break;
		case 1:
			selector = @selector(increaseDifficulty);
			break;
		case -1:
			selector = @selector(decreaseDifficulty);
			break;
	}
	NSEnumerator *enumerator = [[self selectedOrAllWords] objectEnumerator];
	ProVocWord *word;
	while (word = [enumerator nextObject]) {
		[self willChangeWord:word];
		[word performSelector:selector];
		[self didChangeWord:word];

        float difficulty = [word difficulty];
        mMinDifficulty = MIN(mMinDifficulty, difficulty);
        mMaxDifficulty = MAX(mMaxDifficulty, difficulty);
	}
	[self visibleWordsDidChange];
}

-(IBAction)removeAccents:(id)inSender
{
	[self willChangeData];
	[[self selectedOrAllWords] makeObjectsPerformSelector:@selector(removeAccents)];
	[self visibleWordsDidChange];
	[self didChangeData];
}

#pragma mark -

int SORT_BY_DIFFICULT(id left, id right, void *info)
{
	float diffA = [left difficulty];
	float diffB = [right difficulty];
	if (diffA == diffB)
		return 0;
	else if (diffA < diffB)
		return 1;
	else
		return -1;
}

-(NSArray *)wordsToBeTestedFrom:(NSArray *)inWords
{
	id wordsToTest = nil;
	if ([self testWordsToReview]) {
		NSDate *now = [NSDate date];
		wordsToTest = [NSMutableArray array];
		NSEnumerator *enumerator = [inWords objectEnumerator];
		ProVocWord *word;
		while (word = [enumerator nextObject])
			if ([now compare:[word nextReview]] != NSOrderedAscending)
				[wordsToTest addObject:word];
	} else
		wordsToTest = [[inWords mutableCopy] autorelease];

	if ([self testMarked] || mTestOldWords) {
		NSDate *latestDate;
		if (mTestOldUnit < 2)
			latestDate = [[[NSDate date] beginningOfDay] addTimeInterval:(1 - mTestOldNumber * (mTestOldUnit == 0 ? 1 : 7)) * 24 * 60 * 60];
		else {
			latestDate = [[NSDate date] beginningOfMonth];
			int i;
			for (i = 1; i < mTestOldNumber; i++)
				latestDate = [latestDate previousMonth];
		}
		NSEnumerator *enumerator = [wordsToTest objectEnumerator];
		wordsToTest = [NSMutableArray array];
		id labelsToTest = [self labelsToTest];
		ProVocWord *word;
		while (word = [enumerator nextObject])
			if ((![self testMarked] || ([word mark] && [labelsToTest containsIndex:0] || [labelsToTest containsIndex:[word label] + 1]))
				&& (!mTestOldWords || [latestDate compare:[word lastAnswered]] != NSOrderedAscending))
				[wordsToTest addObject:word];
	}
	
	if (mTestLimit) {
		switch (mTestLimitWhat) {
			case 0:
				wordsToTest = [wordsToTest shuffledArray];
				break;
			case 1: // most difficult
				[wordsToTest sortUsingFunction:SORT_BY_DIFFICULT context:nil];
				break;
		}
		int n = MAX(1, mTestLimitNumber);
		n = MIN(n, [wordsToTest count]);
		wordsToTest = [wordsToTest objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, n)]];
	}
	
	return wordsToTest;
}

-(NSArray *)wordsToBeTested
{
	return [self wordsToBeTestedFrom:mWords];
}

-(NSArray *)wordsForMCQAnswers
{
	return mWords;
}

-(IBAction)selectView:(id)inSender
{
	[self setMainTab:[inSender tag]];
}

-(IBAction)startSlideshow:(id)inSender
{
	[self slideshowWithWords:mWords];
}

-(IBAction)startTest:(id)inSender
{
	[self setMainTab:0];
	NSDictionary *parameters = [self parameters];
	if (mTester) {
		mTestIsRunning = YES;
		[mTester resumeTestWithParameters:parameters];
		return;
	}
	
	NSArray *words = [self wordsToBeTested];
    if ([words count] == 0) {
		if ([[self allWords] count] == 0) {
			int returnCode = NSRunAlertPanel(NSLocalizedString(@"No Word To Test Empty Document Alert Title", @""),
											NSLocalizedString(@"No Word To Test Empty Document Alert Message", @""),
											NSLocalizedString(@"No Word To Test Empty Document OK Button", @""),
											NSLocalizedString(@"No Word To Test Empty Document Help Button", @""),
											NSLocalizedString(@"No Word To Test Empty Document Download Button", @""));
			switch (returnCode) {
				case NSAlertDefaultReturn:
					break;
				case NSAlertAlternateReturn:
					[NSApp showHelp:nil];
					break;
				case NSAlertOtherReturn:
					[[NSApp delegate] downloadDocuments:nil];
					break;
			}
			[self setMainTab:1];
		} else
			NSRunAlertPanel(NSLocalizedString(@"No Word To Test Alert Title", @""), NSLocalizedString(@"No Word To Test Alert Message", @""), nil, nil, nil);
        return;
    }
        
    [mTester release];
	Class tester = [ProVocTester class];
	if ([[parameters objectForKey:@"testMCQ"] boolValue])
		tester = [ProVocMCQTester class];
    mTester = [[tester alloc] initWithDocument:self];
	if ([mTester respondsToSelector:@selector(setAnswerWords:withParameters:)])
		[(id)mTester setAnswerWords:[self wordsForMCQAnswers] withParameters:parameters];
	mTestIsRunning = YES;
	[mTester beginTestWithWords:words parameters:parameters sourceLanguage:[self sourceLanguage] targetLanguage:[self targetLanguage]];
}

-(void)testPanelDidClose
{
	[self updateDifficultyLimits];
	[self sortedWordsDidChange];
	[self willChangeData];
	[self didChangeData];
	[self currentPresetValuesDidChange:nil];
}

-(void)testDidFinish
{
    [mTester autorelease];
    mTester = nil;
	mTestIsRunning = NO;
}

-(BOOL)testIsRunning
{
	return mTestIsRunning;
}

-(BOOL)canResumeTest
{
	return mTester != nil;
}

-(BOOL)canModifyTestParameters
{
	return ![self canResumeTest];
}

-(BOOL)tableView:(NSTableView *)inTableView shouldSelectRow:(int)inRowIndex
{
	if (inTableView == mPresetTableView)
		return [self canModifyTestParameters];
	else
		return YES;
}

-(NSString *)startTestButtonTitle
{
	return [self canResumeTest] ? NSLocalizedString(@"Resume Test Button Title", @"") : NSLocalizedString(@"Start Test Button Title", @"");
}

#pragma mark -

-(IBAction)printDocument:(id)inSender
{
    NSView *view = [[ProVocPrintView alloc] initWithDocument:self];
    NSPrintOperation *op = [NSPrintOperation printOperationWithView:view printInfo:[self printInfo]];
	[op setAccessoryView:mPrintAccessoryView];
    [op runOperationModalForWindow:[self window] delegate:self didRunSelector:nil contextInfo:nil];
}

-(IBAction)printCards:(id)inSender
{
	ProVocCardController *controller = [[[ProVocCardController alloc] initWithDocument:self words:mSortedWords] autorelease];
	if (![controller runModal])
		return;
    ProVocCardsView *view = [[[ProVocCardsView alloc] initWithDocument:self words:mSortedWords] autorelease];
    NSPrintOperation *op = [NSPrintOperation printOperationWithView:view printInfo:[self printInfo]];
    [op runOperationModalForWindow:[self window] delegate:self didRunSelector:nil contextInfo:nil];
}

-(IBAction)showGeneralPreferences:(id)inSender
{
    [[ProVocPreferences sharedPreferences] openGeneralView:nil];
}

-(void)toggleInspector:(id)inSender
{
	[[ProVocInspector sharedInspector] toggle];
}

@end

@implementation ProVocDocument (NamePrompt)

-(void)openInputPanel:(NSString *)inPrompt defaultValue:(NSString *)inDefault
{
    [mInputPromptTextField setStringValue:inPrompt];
    [mInputTextField setStringValue:inDefault];
    [NSApp beginSheet:mInputPanel modalForWindow:mMainWindow modalDelegate:self
                    didEndSelector:@selector(inputPanelEnded:returnCode:contextInfo:) contextInfo:NULL];
}

-(void)inputPanelEnded:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if (returnCode == NSOKButton)
        [self performSelector:mInputPanelCallbackSelector withObject:[mInputTextField stringValue]];
}

-(IBAction)cancelInputPanel:(id)inSender
{
    [mInputPanel orderOut:self];
    [NSApp endSheet:mInputPanel returnCode:NSCancelButton];
}

-(IBAction)okInputPanel:(id)inSender
{
    [mInputPanel orderOut:self];
    [NSApp endSheet:mInputPanel returnCode:NSOKButton];
}

@end

@implementation ProVocDocument (Settings)

-(NSString *)testQuestionDescription
{
	NSString *src = [self sourceLanguage];
	NSString *tgt = [self targetLanguage];
	if ([NSLocalizedString(@"Lowercase language in sentence", @"") intValue]) {
		src = [src lowercaseString];
		tgt = [tgt lowercaseString];
	}
	switch ([self testDirection]) {
		case 0:
			return [NSString stringWithFormat:NSLocalizedString(@"Questions in Language %@. Answers in Language %@.", @""), src, tgt];
		case 1:
			return [NSString stringWithFormat:NSLocalizedString(@"Questions in Language %@. Answers in Language %@.", @""), tgt, src];
		case 2: {
			int prob = round([self testDirectionProbability] * 100.0);
			return [NSString stringWithFormat:NSLocalizedString(@"Questions %i%% in Language %@, %i%% in Language %@.", @""), 100 - prob, src, prob, tgt];
		}
		case 3:
			return [NSString stringWithFormat:NSLocalizedString(@"Questions both in Language %@ and in Language %@.", @""), src, tgt];
	}
	return nil;
}

-(BOOL)randomTestDirection
{
	return mTestDirection == 2;
}

-(int)numberOfRetries
{
	return mNumberOfRetries;
}

-(void)setNumberOfRetries:(int)inNumberOfRetries
{
	if (mNumberOfRetries != inNumberOfRetries) {
		[self willChangeValueForKey:@"numberOfRetries"];	
		mNumberOfRetries = inNumberOfRetries;
		[self didChangeValueForKey:@"numberOfRetries"];	
		[self currentPresetValuesDidChange:nil];
	}
}

-(int)testDirection
{
	return mTestDirection;
}

-(void)setTestDirection:(int)inTestDirection
{
	if (mTestDirection != inTestDirection) {
		[self willChangeValueForKey:@"testDirection"];	
		mTestDirection = inTestDirection;
		[self didChangeValueForKey:@"testDirection"];
		[self currentPresetValuesDidChange:nil];
	}
}

-(float)testDirectionProbability
{
	return mTestDirectionProbability;
}

-(void)setTestDirectionProbability:(float)inTestDirectionProbability
{
	if (mTestDirectionProbability != inTestDirectionProbability) {
		[self willChangeValueForKey:@"testDirectionProbability"];	
		mTestDirectionProbability = inTestDirectionProbability;
		[self didChangeValueForKey:@"testDirectionProbability"];
		[self currentPresetValuesDidChange:nil];
	}
}

-(BOOL)dontShuffleWords
{
	return mDontShuffleWords;
}

-(void)setDontShuffleWords:(BOOL)inDontShuffleWords
{
	if (mDontShuffleWords != inDontShuffleWords) {
		[self willChangeValueForKey:@"dontShuffleWords"];	
		mDontShuffleWords = inDontShuffleWords;
		[self didChangeValueForKey:@"dontShuffleWords"];
		[self currentPresetValuesDidChange:nil];
	}
}

-(BOOL)showBacktranslation
{
	return mShowBacktranslation;
}

-(void)setShowBacktranslation:(BOOL)inShowBacktranslation
{
	if (mShowBacktranslation != inShowBacktranslation) {
		[self willChangeValueForKey:@"showBacktranslation"];
		mShowBacktranslation = inShowBacktranslation;
		[self didChangeValueForKey:@"showBacktranslation"];
		[self currentPresetValuesDidChange:nil];
	}
}

-(BOOL)initialSlideshow
{
	return mInitialSlideshow;
}

-(void)setInitialSlideshow:(BOOL)inInitialSlideshow
{
	if (mInitialSlideshow != inInitialSlideshow) {
		[self willChangeValueForKey:@"initialSlideshow"];
		mInitialSlideshow = inInitialSlideshow;
		[self didChangeValueForKey:@"initialSlideshow"];
		[self currentPresetValuesDidChange:nil];
	}
}

-(BOOL)autoPlayMedia
{
	return mAutoPlayMedia;
}

-(void)setAutoPlayMedia:(BOOL)inAutoPlayMedia
{
	if (mAutoPlayMedia != inAutoPlayMedia) {
		[self willChangeValueForKey:@"autoPlayMedia"];
		mAutoPlayMedia = inAutoPlayMedia;
		[self didChangeValueForKey:@"autoPlayMedia"];
		[self currentPresetValuesDidChange:nil];
	}
}

-(BOOL)imageMCQ
{
	return mImageMCQ;
}

-(void)setImageMCQ:(BOOL)inImageMCQ
{
	if (mImageMCQ != inImageMCQ) {
		[self willChangeValueForKey:@"imageMCQ"];
		mImageMCQ = inImageMCQ;
		[self didChangeValueForKey:@"imageMCQ"];
		[self currentPresetValuesDidChange:nil];
	}
}

-(int)mediaHideQuestion
{
	return mMediaHideQuestion;
}

-(void)setMediaHideQuestion:(int)inMediaHideQuestion
{
	if (mMediaHideQuestion != inMediaHideQuestion) {
		[self willChangeValueForKey:@"mediaHideQuestion"];
		mMediaHideQuestion = inMediaHideQuestion;
		[self didChangeValueForKey:@"mediaHideQuestion"];
		[self currentPresetValuesDidChange:nil];
	}
}

-(BOOL)useSpeechSynthesizer
{
	return mUseSpeechSynthesizer;
}

-(void)setUseSpeechSynthesizer:(BOOL)inUseSpeechSynthesizer
{
	if (mUseSpeechSynthesizer != inUseSpeechSynthesizer) {
		[self willChangeValueForKey:@"useSpeechSynthesizer"];
		mUseSpeechSynthesizer = inUseSpeechSynthesizer;
		[self didChangeValueForKey:@"useSpeechSynthesizer"];
		[self currentPresetValuesDidChange:nil];
	}
}

-(NSString *)voiceIdentifier
{
	return mVoiceIdentifier;
}

-(void)setVoiceIdentifier:(NSString *)inVoiceIdentifier
{
	if (mVoiceIdentifier != inVoiceIdentifier) {
		[self willChangeValueForKey:@"voiceIdentifier"];
		[mVoiceIdentifier release];
		mVoiceIdentifier = [inVoiceIdentifier retain];
		[self didChangeValueForKey:@"voiceIdentifier"];
		[self currentPresetValuesDidChange:nil];
		[NSSpeechSynthesizer setDefaultVoice:mVoiceIdentifier];
	}
}

-(NSArray *)availableVoiceIdentifiers
{
	static NSArray *identifiers = nil;
	if (!identifiers) {
		NSArray *allowedGenders = [NSArray arrayWithObjects:NSVoiceGenderMale, NSVoiceGenderFemale, nil];
		NSMutableArray *array = [NSMutableArray array];
		NSEnumerator *enumerator = [[NSSpeechSynthesizer availableVoices] objectEnumerator];
		NSString *voice;
		while (voice = [enumerator nextObject])
			if ([allowedGenders containsObject:[[NSSpeechSynthesizer attributesForVoice:voice] objectForKey:NSVoiceGender]])
				[array addObject:voice];
		identifiers = [array copy];
	}
	return identifiers;
}

-(NSArray *)availableVoices
{
	NSMutableArray *voices = [NSMutableArray array];
	[voices addObject:NSLocalizedString(@"Default Voice", @"")];
	NSEnumerator *enumerator = [[self availableVoiceIdentifiers] objectEnumerator];
	NSString *voiceIdentifier;
	while (voiceIdentifier = [enumerator nextObject])
		[voices addObject:[[NSSpeechSynthesizer attributesForVoice:voiceIdentifier] objectForKey:NSVoiceName]];
	return voices;
}

-(int)selectedVoice
{
	int index = [[self availableVoiceIdentifiers] indexOfObject:[self voiceIdentifier]];
	if (index == NSNotFound)
		return 0;
	else
		return index + 1;
}

-(void)setSelectedVoice:(int)inVoice
{
	NSString *identifier = nil;
	if (inVoice > 0)
		identifier = [[self availableVoiceIdentifiers] objectAtIndex:inVoice - 1];
	[self setVoiceIdentifier:identifier];
}

-(int)timer
{
	return mTimer;
}

-(void)setTimer:(int)inTimer
{
	if (mTimer != inTimer) {
		[self willChangeValueForKey:@"timer"];
		mTimer = inTimer;
		[self didChangeValueForKey:@"timer"];
		[self currentPresetValuesDidChange:nil];
	}
}

-(BOOL)hideTimerDuration
{
	return mTimer != 2;
}

-(float)timerDuration
{
	return mTimerDuration;
}

-(void)setTimerDuration:(float)inTimerDuration
{
	if (mTimerDuration != inTimerDuration) {
		[self willChangeValueForKey:@"timerDuration"];
		mTimerDuration = inTimerDuration;
		[self didChangeValueForKey:@"timerDuration"];
		[self currentPresetValuesDidChange:nil];
	}
}

-(int)testKind
{
	return mTestKind;
}

-(void)setTestKind:(int)inTestKind
{
	if (mTestKind != inTestKind) {
		[self willChangeValueForKey:@"testKind"];	
		[self willChangeValueForKey:@"normalTestMode"];	
		[self willChangeValueForKey:@"continuousTestMode"];	
		[self willChangeValueForKey:@"untilLearnedTestMode"];	
		mTestKind = inTestKind;
		[self didChangeValueForKey:@"testKind"];	
		[self didChangeValueForKey:@"normalTestMode"];	
		[self didChangeValueForKey:@"continuousTestMode"];	
		[self didChangeValueForKey:@"untilLearnedTestMode"];	
		[self currentPresetValuesDidChange:nil];
	}
}

-(BOOL)testWordsToReview
{
	return mTestWordsToReview;
}

-(void)setTestWordsToReview:(BOOL)inTestWordsToReview
{
	if (mTestWordsToReview != inTestWordsToReview) {
		[self willChangeValueForKey:@"testWordsToReview"];	
		mTestWordsToReview = inTestWordsToReview;
		[self didChangeValueForKey:@"testWordsToReview"];	
		[self currentPresetValuesDidChange:nil];
	}
}

-(BOOL)testMarked
{
	return mTestMarked;
}

-(void)setTestMarked:(BOOL)inTestMarked
{
	if (mTestMarked != inTestMarked) {
		[self willChangeValueForKey:@"testMarked"];	
		mTestMarked = inTestMarked;
		[self didChangeValueForKey:@"testMarked"];	
		[self currentPresetValuesDidChange:nil];
	}
}

-(id)labelsToTest
{
	if ([NSApp systemVersion] < 0x1040)
		return [mLabelTableView selectedRowIndexes];
	else
		return mLabelsToTest;
}

-(void)tableViewSelectionDidChange:(NSNotification *)inNotification
{
	NSTableView *tableView = [inNotification object];
	if (tableView == mPresetTableView) {
		mIndexOfCurrentPresets = [mPresetTableView selectedRow];
		[self currentPresetDidChange:nil];
	} else if (tableView == mLabelTableView) {
		[self willChangeValueForKey:@"pageSelectionTitle"];
		[self didChangeValueForKey:@"pageSelectionTitle"];
		[self currentPresetValuesDidChange:nil];
	} else if (tableView == mWordTableView)
		[self selectedWordsDidChange:nil];
}

-(void)setLabelsToTest:(id)inLabelsToTest
{
	if ([NSApp systemVersion] < 0x1040) {
		if (!mLabelTableView)
			[self performSelector:_cmd withObject:inLabelsToTest afterDelay:0.0];
		else if (![[mLabelTableView selectedRowIndexes] isEqual:inLabelsToTest]) {
			[mLabelTableView selectRowIndexes:inLabelsToTest byExtendingSelection:NO];
			[self currentPresetValuesDidChange:nil];
		}
	} else
		if (![mLabelsToTest isEqual:inLabelsToTest]) {
			[self willChangeValueForKey:@"labelsToTest"];	
			[mLabelsToTest release];
			mLabelsToTest = [inLabelsToTest retain];
			[self didChangeValueForKey:@"labelsToTest"];	
			[self currentPresetValuesDidChange:nil];
		}
}

-(BOOL)testOldWords
{
	return mTestOldWords;
}

-(void)setTestOldWords:(BOOL)inTestOldWords
{
	if (mTestOldWords != inTestOldWords) {
		[self willChangeValueForKey:@"testOldWords"];	
		mTestOldWords = inTestOldWords;
		[self didChangeValueForKey:@"testOldWords"];	
		[self currentPresetValuesDidChange:nil];
	}
}

-(int)testOldNumber
{
	return mTestOldNumber;
}

-(void)setTestOldNumber:(int)inTestOldNumber
{
	if (mTestOldNumber != inTestOldNumber) {
		[self willChangeValueForKey:@"testOldNumber"];	
		mTestOldNumber = inTestOldNumber;
		[self didChangeValueForKey:@"testOldNumber"];	
		[self currentPresetValuesDidChange:nil];
	}
}

-(int)testOldUnit
{
	return mTestOldUnit;
}

-(void)setTestOldUnit:(int)inTestOldUnit
{
	if (mTestOldUnit != inTestOldUnit) {
		[self willChangeValueForKey:@"testOldUnit"];	
		mTestOldUnit = inTestOldUnit;
		[self didChangeValueForKey:@"testOldUnit"];	
		[self currentPresetValuesDidChange:nil];
	}
}

-(BOOL)testLimit
{
	return mTestLimit;
}

-(void)setTestLimit:(BOOL)inTestLimit
{
	if (mTestLimit != inTestLimit) {
		[self willChangeValueForKey:@"testLimit"];	
		mTestLimit = inTestLimit;
		[self didChangeValueForKey:@"testLimit"];	
		[self currentPresetValuesDidChange:nil];
	}
}

-(int)testLimitNumber
{
	return mTestLimitNumber;
}

-(void)setTestLimitNumber:(int)inTestLimitNumber
{
	if (mTestLimitNumber != inTestLimitNumber) {
		[self willChangeValueForKey:@"testLimitNumber"];	
		mTestLimitNumber = inTestLimitNumber;
		[self didChangeValueForKey:@"testLimitNumber"];	
		[self currentPresetValuesDidChange:nil];
	}
}

-(int)testLimitWhat
{
	return mTestLimitWhat;
}

-(void)setTestLimitWhat:(int)inTestLimitWhat
{
	if (mTestLimitWhat != inTestLimitWhat) {
		[self willChangeValueForKey:@"testLimitWhat"];	
		mTestLimitWhat = inTestLimitWhat;
		[self didChangeValueForKey:@"testLimitWhat"];	
		[self currentPresetValuesDidChange:nil];
	}
}

-(int)lateComments
{
	return mLateComments;
}

-(void)setLateComments:(int)inLateComments
{
	if (mLateComments != inLateComments) {
		[self willChangeValueForKey:@"lateComments"];	
		mLateComments = inLateComments;
		[self didChangeValueForKey:@"lateComments"];	
		[self currentPresetValuesDidChange:nil];
	}
}

-(BOOL)testMCQ
{
	return mTestMCQ;
}

-(void)setTestMCQ:(BOOL)inTestMCQ
{
	if (mTestMCQ != inTestMCQ) {
		[self willChangeValueForKey:@"testMCQ"];	
		mTestMCQ = inTestMCQ;
		[self didChangeValueForKey:@"testMCQ"];	
		[self currentPresetValuesDidChange:nil];
	}
}

-(BOOL)labelsDisplayed
{
	return mDisplayLabels != 2;
}

-(int)displayLabels
{
	return mDisplayLabels;
}

-(void)setDisplayLabels:(int)inDisplayLabels
{
	if (mDisplayLabels != inDisplayLabels) {
		[self willChangeValueForKey:@"displayLabels"];	
		mDisplayLabels = inDisplayLabels;
		[self didChangeValueForKey:@"displayLabels"];	
		[self currentPresetValuesDidChange:nil];
	}
}

-(BOOL)colorWindowWithLabel
{
	return mColorWindowWithLabel;
}

-(void)setColorWindowWithLabel:(BOOL)inColorWindowWithLabel
{
	if (mColorWindowWithLabel != inColorWindowWithLabel) {
		[self willChangeValueForKey:@"colorWindowWithLabel"];	
		mColorWindowWithLabel = inColorWindowWithLabel;
		[self didChangeValueForKey:@"colorWindowWithLabel"];	
		[self currentPresetValuesDidChange:nil];
	}
}

-(BOOL)displayLabelText
{
	return mDisplayLabelText;
}

-(void)setDisplayLabelText:(BOOL)inDisplayLabelText
{
	if (mDisplayLabelText != inDisplayLabelText) {
		[self willChangeValueForKey:@"displayLabelText"];	
		mDisplayLabelText = inDisplayLabelText;
		[self didChangeValueForKey:@"displayLabelText"];	
		[self currentPresetValuesDidChange:nil];
	}
}

-(int)testMCQNumber
{
	return mTestMCQNumber;
}

-(void)setTestMCQNumber:(int)inTestMCQNumber
{
	if (mTestMCQNumber != inTestMCQNumber) {
		[self willChangeValueForKey:@"testMCQNumber"];	
		mTestMCQNumber = inTestMCQNumber;
		[self didChangeValueForKey:@"testMCQNumber"];	
		[self currentPresetValuesDidChange:nil];
	}
}

-(BOOL)delayedMCQ
{
	return mDelayedMCQ;
}

-(void)setDelayedMCQ:(BOOL)inDelayedMCQ
{
	if (mDelayedMCQ != inDelayedMCQ) {
		[self willChangeValueForKey:@"delayedMCQ"];	
		mDelayedMCQ = inDelayedMCQ;
		[self didChangeValueForKey:@"delayedMCQ"];	
		[self currentPresetValuesDidChange:nil];
	}
}

-(float)testDifficulty
{
	return mTestDifficulty;
}

-(void)setTestDifficulty:(float)inTestDifficulty
{
	if (mTestDifficulty != inTestDifficulty) {
		[self willChangeValueForKey:@"testDifficulty"];	
		mTestDifficulty = inTestDifficulty;
		[self didChangeValueForKey:@"testDifficulty"];
	}
}

-(NSString *)sourceLanguage
{
    return [mProVocData sourceLanguage];
}

-(NSString *)targetLanguage
{
    return [mProVocData targetLanguage];
}

-(NSString *)sourceLanguageCaption
{
	return [NSString stringWithFormat:@"%@:", [self sourceLanguage]];
}

-(NSString *)targetLanguageCaption
{
	return [NSString stringWithFormat:@"%@:", [self targetLanguage]];
}

-(NSString *)displayWithSource
{
	return [NSString stringWithFormat:NSLocalizedString(@"Display with %@", @""), [self sourceLanguage]];
}

-(NSString *)displayWithTarget
{
	return [NSString stringWithFormat:NSLocalizedString(@"Display with %@", @""), [self targetLanguage]];
}

-(NSString *)editCommentString
{
	static NSMutableString *string = nil;
	if (!string)
		string = [[NSMutableString alloc] initWithString:@""];
	else
		[string setString:@""];
		
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults boolForKey:PVPrefsUseSynonymSeparator])
		[string appendFormat:NSLocalizedString(@"Synonym Separator Comment String (%@)", @""), [defaults objectForKey:PVPrefSynonymSeparator]];
	if ([defaults boolForKey:PVPrefsUseCommentsSeparator]) {
		if ([string length] > 0)
			[string appendString:NSLocalizedString(@"Comment String Separator", @"")];
		[string appendFormat:NSLocalizedString(@"Comment Separator Comment String (%@)", @""), [defaults objectForKey:PVPrefCommentsSeparator]];
	}
	return string;
}

-(void)setInputFieldHeight:(float)inHeight field:(NSTextField *)inField container:(NSView *)inContainer aboveViews:(NSArray *)inAboveViews
{
	NSRect frame;
	float deltaHeight = inHeight - [inField frame].size.height;
	frame = [inContainer frame];
	frame.size.height += deltaHeight;
	[inContainer setFrame:frame];
	NSEnumerator *enumerator = [inAboveViews objectEnumerator];
	NSView *view;
	BOOL first = YES;
	while (view = [enumerator nextObject]) {
		frame = [view frame];
		frame.origin.y += deltaHeight;
		if (first)
			frame.size.height -= deltaHeight;
		[view setFrame:frame];
		[view setNeedsDisplay:YES];
		first = NO;
	}
	[inContainer setNeedsDisplay:YES];
	[[inContainer superview] setNeedsDisplay:YES];
	[inField setStringValue:[inField stringValue]];
}

-(void)inputFontSizeIsChanging
{
	NSNotification *notification = [NSNotification notificationWithName:ProVocInputFontSizeDidChangeNotification object:nil];
	[[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostWhenIdle coalesceMask:NSNotificationCoalescingOnName forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

-(NSString *)fontFamilyName
{
	return [[NSFont systemFontOfSize:0] familyName];
}

-(float)fontSize
{
	return [NSFont systemFontSize];
}

-(NSString *)sourceFontFamilyName
{
	NSString *name = [mGlobalPreferences objectForKey:@"sourceFontFamilyName"];
	if (name)
		return name;
	else
		return [[NSFont systemFontOfSize:0] familyName];
}

-(void)setSourceFontFamilyName:(NSString *)inName
{
	[self willChangeValueForKey:@"sourceFontFamilyName"];
	if (inName)
		[mGlobalPreferences setObject:inName forKey:@"sourceFontFamilyName"];
	[self didChangeValueForKey:@"sourceFontFamilyName"];
	[self documentParameterDidChange:nil];
}

-(float)sourceFontSize
{
	id value = [mGlobalPreferences objectForKey:@"sourceFontSize"];
	if (value)
		return [value floatValue];
	else
		return [NSFont systemFontSize];
}

-(void)setSourceFontSize:(float)inSize
{
	[self willChangeValueForKey:@"sourceFontSize"];
	[mGlobalPreferences setObject:[NSNumber numberWithFloat:inSize] forKey:@"sourceFontSize"];
	[self didChangeValueForKey:@"sourceFontSize"];
	[self documentParameterDidChange:nil];
	[self inputFontSizeIsChanging];
}

-(float)sourceTestFontSize
{
	id value = [mGlobalPreferences objectForKey:@"sourceTestFontSize"];
	if (value)
		return [value floatValue];
	else
		return [NSFont systemFontSize];
}

-(void)setSourceTestFontSize:(float)inSize
{
	[self willChangeValueForKey:@"sourceTestFontSize"];
	[mGlobalPreferences setObject:[NSNumber numberWithFloat:inSize] forKey:@"sourceTestFontSize"];
	[self didChangeValueForKey:@"sourceTestFontSize"];
	[self documentParameterDidChange:nil];
}

-(NSWritingDirection)sourceWritingDirection
{
	return [[mGlobalPreferences objectForKey:@"sourceWritingDirection"] intValue];
}

-(void)setSourceWritingDirection:(NSWritingDirection)inDirection
{
	[self willChangeValueForKey:@"sourceWritingDirection"];
	[mGlobalPreferences setObject:[NSNumber numberWithInt:inDirection] forKey:@"sourceWritingDirection"];
	[self didChangeValueForKey:@"sourceWritingDirection"];
	[self documentParameterDidChange:nil];
	[self writingDirectionDidChange];
}

-(NSString *)targetFontFamilyName
{
	NSString *name = [mGlobalPreferences objectForKey:@"targetFontFamilyName"];
	if (name)
		return name;
	else
		return [[NSFont systemFontOfSize:0] familyName];
}

-(void)setTargetFontFamilyName:(NSString *)inName
{
	[self willChangeValueForKey:@"targetFontFamilyName"];
	if (inName)
		[mGlobalPreferences setObject:inName forKey:@"targetFontFamilyName"];
	[self didChangeValueForKey:@"targetFontFamilyName"];
	[self documentParameterDidChange:nil];
}

-(float)targetFontSize
{
	id value = [mGlobalPreferences objectForKey:@"targetFontSize"];
	if (value)
		return [value floatValue];
	else
		return [NSFont systemFontSize];
}

-(void)setTargetFontSize:(float)inSize
{
	[self willChangeValueForKey:@"targetFontSize"];
	[mGlobalPreferences setObject:[NSNumber numberWithFloat:inSize] forKey:@"targetFontSize"];
	[self didChangeValueForKey:@"targetFontSize"];
	[self documentParameterDidChange:nil];
	[self inputFontSizeIsChanging];
}

-(float)targetTestFontSize
{
	id value = [mGlobalPreferences objectForKey:@"targetTestFontSize"];
	if (value)
		return [value floatValue];
	else
		return [NSFont systemFontSize];
}

-(void)setTargetTestFontSize:(float)inSize
{
	[self willChangeValueForKey:@"targetTestFontSize"];
	[mGlobalPreferences setObject:[NSNumber numberWithFloat:inSize] forKey:@"targetTestFontSize"];
	[self didChangeValueForKey:@"targetTestFontSize"];
	[self documentParameterDidChange:nil];
}

-(NSWritingDirection)targetWritingDirection
{
	return [[mGlobalPreferences objectForKey:@"targetWritingDirection"] intValue];
}

-(void)setTargetWritingDirection:(NSWritingDirection)inDirection
{
	[self willChangeValueForKey:@"targetWritingDirection"];
	[mGlobalPreferences setObject:[NSNumber numberWithInt:inDirection] forKey:@"targetWritingDirection"];
	[self didChangeValueForKey:@"targetWritingDirection"];
	[self documentParameterDidChange:nil];
	[self writingDirectionDidChange];
}

-(NSString *)commentFontFamilyName
{
	NSString *name = [mGlobalPreferences objectForKey:@"commentFontFamilyName"];
	if (name)
		return name;
	else
		return [[NSFont systemFontOfSize:0] familyName];
}

-(void)setCommentFontFamilyName:(NSString *)inName
{
	[self willChangeValueForKey:@"commentFontFamilyName"];
	if (inName)
		[mGlobalPreferences setObject:inName forKey:@"commentFontFamilyName"];
	[self didChangeValueForKey:@"commentFontFamilyName"];
	[self documentParameterDidChange:nil];
}

-(float)commentFontSize
{
	id value = [mGlobalPreferences objectForKey:@"commentFontSize"];
	if (value)
		return [value floatValue];
	else
		return [NSFont systemFontSize];
}

-(void)setCommentFontSize:(float)inSize
{
	[self willChangeValueForKey:@"commentFontSize"];
	[mGlobalPreferences setObject:[NSNumber numberWithFloat:inSize] forKey:@"commentFontSize"];
	[self didChangeValueForKey:@"commentFontSize"];
	[self documentParameterDidChange:nil];
	[self inputFontSizeIsChanging];
}

-(float)commentTestFontSize
{
	id value = [mGlobalPreferences objectForKey:@"commentTestFontSize"];
	if (value)
		return [value floatValue];
	else
		return [NSFont systemFontSize];
}

-(void)setCommentTestFontSize:(float)inSize
{
	[self willChangeValueForKey:@"commentTestFontSize"];
	[mGlobalPreferences setObject:[NSNumber numberWithFloat:inSize] forKey:@"commentTestFontSize"];
	[self didChangeValueForKey:@"commentTestFontSize"];
	[self documentParameterDidChange:nil];
}

-(NSWritingDirection)commentWritingDirection
{
	return [[mGlobalPreferences objectForKey:@"commentWritingDirection"] intValue];
}

-(void)setCommentWritingDirection:(NSWritingDirection)inDirection
{
	[self willChangeValueForKey:@"commentWritingDirection"];
	[mGlobalPreferences setObject:[NSNumber numberWithInt:inDirection] forKey:@"commentWritingDirection"];
	[self didChangeValueForKey:@"commentWritingDirection"];
	[self documentParameterDidChange:nil];
	[self writingDirectionDidChange];
}

-(float)rowHeightForFontFamilyName:(NSString *)inFamilyName size:(float)inSize
{
	NSFont *font = [[NSFontManager sharedFontManager] fontWithFamily:inFamilyName traits:0 weight:0 size:inSize];
	if ([NSApp systemVersion] >= 0x1040) {
		NSString *text = @"WQpgjhl";
		NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:font, NSFontAttributeName, nil];
		NSRect r = [text boundingRectWithSize:NSMakeSize(FLT_MAX, FLT_MAX) options:NSStringDrawingUsesFontLeading attributes:attributes];
		[attributes release];
		return ceil(r.size.height);
	} else {
		NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
		float height = [layoutManager defaultLineHeightForFont:font];
		float leading = 2;
		height = MAX(height + 1, ceil([font ascender] - [font descender] + leading));
		[layoutManager release];
		return height;
	}
}

-(float)rowHeight
{
	float height = 8;
	height = MAX(height, [self rowHeightForFontFamilyName:[self sourceFontFamilyName] size:[self sourceFontSize]]);
	height = MAX(height, [self rowHeightForFontFamilyName:[self targetFontFamilyName] size:[self targetFontSize]]);
	height = MAX(height, [self rowHeightForFontFamilyName:[self commentFontFamilyName] size:[self commentFontSize]]);
	return height;
}

-(float)fieldHeightForFontFamilyName:(NSString *)inFamilyName size:(float)inSize
{
	float size = MIN([PVInputFontSizeTransformer maxSize], inSize);
	float height = [self rowHeightForFontFamilyName:inFamilyName size:size];
	height += 5;
	return MAX(22, height);
}

-(void)inputFontSizeDidChange:(id)inSender
{
	float height = [self fieldHeightForFontFamilyName:[self sourceFontFamilyName] size:[self sourceFontSize]];
	[self setInputFieldHeight:height field:mSourceTextField container:mSourceInputView aboveViews:[NSArray arrayWithObjects:mAboveInputView, nil]];
	height = [self fieldHeightForFontFamilyName:[self targetFontFamilyName] size:[self targetFontSize]];
	[self setInputFieldHeight:height field:mTargetTextField container:mTargetInputView aboveViews:[NSArray arrayWithObjects:mAboveInputView, mSourceInputView, nil]];
	height = [self fieldHeightForFontFamilyName:[self commentFontFamilyName] size:[self commentFontSize]];
	[self setInputFieldHeight:height field:mCommentTextField container:mCommentInputView aboveViews:[NSArray arrayWithObjects:mAboveInputView, mSourceInputView, mTargetInputView, nil]];
}

-(void)setWritingDirection:(NSWritingDirection)inDirection forTextField:(NSTextField *)inTextField columnWithIdentifier:(NSString *)inColumnIdentifier
{
//	[inTextField setWritingDirection:inDirection];
	NSTableColumn *column = [mWordTableView tableColumnWithIdentifier:inColumnIdentifier];
	[[column dataCell] setAlignment:inDirection == NSWritingDirectionRightToLeft ? NSRightTextAlignment : NSLeftTextAlignment];
}

-(void)writingDirectionDidChange
{
	[self setWritingDirection:[self sourceWritingDirection] forTextField:mSourceTextField columnWithIdentifier:@"Source"];
	[self setWritingDirection:[self targetWritingDirection] forTextField:mTargetTextField columnWithIdentifier:@"Target"];
	[self setWritingDirection:[self commentWritingDirection] forTextField:mCommentTextField columnWithIdentifier:@"Comment"];
	[mWordTableView reloadData];
}

-(void)observeValueForKeyPath:(NSString *)inKeyPath ofObject:(id)inObject change:(NSDictionary *)inChange context:(void *)inContext
{
	if (inContext) {
		[self willChangeValueForKey:inContext];
		[self didChangeValueForKey:inContext];
	} else if ([self isCurrentDocument]) {
		if ([inKeyPath isEqual:@"values.sourceFontFamilyName"])
			[self setSourceFontFamilyName:[inObject valueForKeyPath:inKeyPath]];
		if ([inKeyPath isEqual:@"values.sourceFontSize"])
			[self setSourceFontSize:[[inObject valueForKeyPath:inKeyPath] floatValue]];
		if ([inKeyPath isEqual:@"values.sourceTestFontSize"])
			[self setSourceTestFontSize:[[inObject valueForKeyPath:inKeyPath] floatValue]];
		if ([inKeyPath isEqual:@"values.sourceWritingDirection"])
			[self setSourceWritingDirection:[[inObject valueForKeyPath:inKeyPath] intValue]];
		if ([inKeyPath isEqual:@"values.targetFontFamilyName"])
			[self setTargetFontFamilyName:[inObject valueForKeyPath:inKeyPath]];
		if ([inKeyPath isEqual:@"values.targetFontSize"])
			[self setTargetFontSize:[[inObject valueForKeyPath:inKeyPath] floatValue]];
		if ([inKeyPath isEqual:@"values.targetTestFontSize"])
			[self setTargetTestFontSize:[[inObject valueForKeyPath:inKeyPath] floatValue]];
		if ([inKeyPath isEqual:@"values.targetWritingDirection"])
			[self setTargetWritingDirection:[[inObject valueForKeyPath:inKeyPath] intValue]];
		if ([inKeyPath isEqual:@"values.commentFontFamilyName"])
			[self setCommentFontFamilyName:[inObject valueForKeyPath:inKeyPath]];
		if ([inKeyPath isEqual:@"values.commentFontSize"])
			[self setCommentFontSize:[[inObject valueForKeyPath:inKeyPath] floatValue]];
		if ([inKeyPath isEqual:@"values.commentTestFontSize"])
			[self setCommentTestFontSize:[[inObject valueForKeyPath:inKeyPath] floatValue]];
		if ([inKeyPath isEqual:@"values.commentWritingDirection"])
			[self setCommentWritingDirection:[[inObject valueForKeyPath:inKeyPath] intValue]];
	}
}

@end

@implementation ProVocDocument (History)

-(BOOL)canClearHistory
{
	return [mHistories count] > 0;
}

-(void)removeLastHistory
{
	if ([mHistories count] > 0) {
		[self willChangeValueForKey:@"canClearHistory"];
		[mHistories removeLastObject];
		[mHistoryView reloadData];
		[self didChangeValueForKey:@"canClearHistory"];
	}
}

-(void)addHistory:(id)inHistory
{
	[self willChangeValueForKey:@"canClearHistory"];
	if (!mHistories)
		mHistories = [[NSMutableArray alloc] initWithCapacity:0];
	[mHistories addObject:inHistory];
	[mHistoryView reloadData];
	[self didChangeValueForKey:@"canClearHistory"];
}

-(IBAction)clearHistory:(id)inSender
{
	[self willChangeHistories];
	[self willChangeValueForKey:@"canClearHistory"];
	[mHistories removeAllObjects];
	[mHistoryView reloadData];
	[self didChangeValueForKey:@"canClearHistory"];
	[self didChangeHistories];
}

-(int)numberOfHistories
{
	return [mHistories count];
}

-(ProVocHistory *)historyAtIndex:(int)inIndex
{
	return [mHistories objectAtIndex:inIndex];
}

@end

@interface DebugView : NSView

@end

@implementation DebugView

-(void)drawRect:(NSRect)inRect
{
	[[NSColor blackColor] set];
	NSFrameRect([self bounds]);
}

@end

@implementation ProVocDocument (Undo)

//#define PseudoKeyedArchiver NSKeyedArchiver
//#define PseudoKeyedUnarchiver NSKeyedUnarchiver

-(void)setData:(NSData *)inData forWord:(id)inIdentifier
{
	ProVocWord *newWord = [PseudoKeyedUnarchiver unarchiveObjectWithData:inData];
	ProVocWord *oldWord = [mProVocData childWithIdentifier:inIdentifier];
	
	[self willChangeWord:oldWord];
	ProVocPage *page = [oldWord page];
	NSMutableArray *words = (NSMutableArray *)[page words];
	[words replaceObjectAtIndex:[words indexOfObjectIdenticalTo:oldWord] withObject:newWord];
	[newWord setPage:page];
	[self didChangeWord:oldWord];
	
	[self wordsDidChange];
	[self selectedWordsDidChange:nil];
}

-(void)willChangeWord:(ProVocWord *)inWord
{
	[[[self undoManager] prepareWithInvocationTarget:self] setData:[mProVocData dataForWord:inWord] forWord:[mProVocData identifierForWord:inWord]];
}

-(void)didChangeWord:(ProVocWord *)inWord
{
}

-(void)setData:(NSData *)inData forSource:(id)inIdentifier
{
	ProVocSource *newSource = [PseudoKeyedUnarchiver unarchiveObjectWithData:inData];
	ProVocSource *oldSource = [mProVocData childWithIdentifier:inIdentifier];
	
	[self willChangeSource:oldSource];
	ProVocChapter *chapter = [oldSource parent];
	NSMutableArray *sources = (NSMutableArray *)[chapter children];
	[sources replaceObjectAtIndex:[sources indexOfObjectIdenticalTo:oldSource] withObject:newSource];
	[newSource setParent:chapter];
	[self didChangeSource:oldSource];
	
	[self pagesDidChange];
	[self selectedWordsDidChange:nil];
}

-(void)willChangeSource:(ProVocSource *)inSource
{
	[[[self undoManager] prepareWithInvocationTarget:self] setData:[mProVocData dataForSource:inSource] forSource:[mProVocData identifierForSource:inSource]];
}

-(void)didChangeSource:(ProVocSource *)inSource
{
}

-(NSData *)data
{
	NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:mProVocData, @"Data",
											[mPageOutlineView expandedState], @"PageExpandedState",
											[mPageOutlineView selectedRowIndexes], @"SelectedPages",
											nil];
	return [PseudoKeyedArchiver archivedDataWithRootObject:info];
}

-(void)setData:(NSData *)inData
{
	[self willChangeData];
	NSDictionary *info = [PseudoKeyedUnarchiver unarchiveObjectWithData:inData];
	[mProVocData release];
	mProVocData = [[info objectForKey:@"Data"] retain];
	[self didChangeData];
	
	[self pagesDidChange];
	[mPageOutlineView setExpandedState:[info objectForKey:@"PageExpandedState"]];
	id selectedIndexes = [info objectForKey:@"SelectedPages"];
	[mPageOutlineView selectRowIndexes:selectedIndexes byExtendingSelection:NO];
	[mPageOutlineView scrollRowToVisible:[selectedIndexes lastIndex]];
	[mPageOutlineView scrollRowToVisible:[selectedIndexes firstIndex]];
	[self selectedWordsDidChange:nil];
}

-(void)willChangeData
{
	[[[self undoManager] prepareWithInvocationTarget:self] setData:[self data]];
}

-(void)didChangeData
{
}

-(NSData *)historyData
{
	return [PseudoKeyedArchiver archivedDataWithRootObject:mHistories];
}

-(void)setHistoryData:(NSData *)inData
{
	[self willChangeHistories];
	[self willChangeValueForKey:@"canClearHistory"];
	id histories = [PseudoKeyedUnarchiver unarchiveObjectWithData:inData];
	[mHistories release];
	mHistories = [histories retain];
	[mHistoryView reloadData];
	[self didChangeValueForKey:@"canClearHistory"];
	[self didChangeHistories];
}

-(void)willChangeHistories
{
	[[[self undoManager] prepareWithInvocationTarget:self] setHistoryData:[self historyData]];
}

-(void)didChangeHistories
{
}

-(NSData *)presetData
{
	NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:[self presets], @"Presets",
											[mPresetTableView selectedRowIndexes], @"SelectedPreset",
											nil];
	return [PseudoKeyedArchiver archivedDataWithRootObject:info];
}

-(void)setPresetData:(NSData *)inData
{
	[self willChangePresets];
	NSDictionary *info = [PseudoKeyedUnarchiver unarchiveObjectWithData:inData];
	[mPresets release];
	mPresets = [[info objectForKey:@"Presets"] retain];
	[self presetsDidChange:nil];
	id selectedIndexes = [info objectForKey:@"SelectedPreset"];
	[mPresetTableView selectRowIndexes:selectedIndexes byExtendingSelection:NO];
	[mPresetTableView scrollRowToVisible:[selectedIndexes lastIndex]];
	[mPresetTableView scrollRowToVisible:[selectedIndexes firstIndex]];
	[self didChangePresets];
}

-(void)willChangePresets
{
	[[[self undoManager] prepareWithInvocationTarget:self] setPresetData:[self presetData]];
}

-(void)didChangePresets
{
}

-(NSData *)languageData
{
	NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:[mProVocData sourceLanguage], @"SourceLanguage",
											[mProVocData targetLanguage], @"TargetLanguage",
											nil];
	return [PseudoKeyedArchiver archivedDataWithRootObject:info];
}

-(void)setLanguageData:(NSData *)inData
{
	[self willChangeLanguages];
	NSDictionary *info = [PseudoKeyedUnarchiver unarchiveObjectWithData:inData];
	[mProVocData setSourceLanguage:[info objectForKey:@"SourceLanguage"]];
	[mProVocData setTargetLanguage:[info objectForKey:@"TargetLanguage"]];
	[self languagesDidChange];
	[self didChangeLanguages];
}

-(void)willChangeLanguages
{
	[[[self undoManager] prepareWithInvocationTarget:self] setLanguageData:[self languageData]];
}

-(void)didChangeLanguages
{
}

@end
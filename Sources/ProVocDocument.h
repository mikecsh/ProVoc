//
//  ProVocDocument.h
//  ProVoc
//
//  Created by bovet on Sat Feb 08 2003.
//  Copyright (c) 2003 Arizona Software. All rights reserved.
//

#import "ProVocData.h"

@class ProVocTester, ProVocActionController, ProVocHistoryView, ProVocHistory;
@class ProVocWord;

@interface ProVocDocument : NSDocument {
	NSDictionary *mLoadedParameters;
	NSMutableDictionary *mGlobalPreferences;
	ProVocData *mProVocData;

	NSMutableArray *mWords;
	NSMutableArray *mSortedWords;
	NSMutableArray *mVisibleWords;
	NSMutableArray *mSelectedPages;
	
	float mMinDifficulty;
	float mMaxDifficulty;
	
	int mNumberOfRetries;
	int mTestDirection;
	BOOL mDontShuffleWords;
	float mTestDirectionProbability;
	int mTestKind;
	BOOL mTestWordsToReview;
	BOOL mTestMarked;
	NSIndexSet *mLabelsToTest;
	int mLateComments;
	int mDisplayLabels;
	BOOL mColorWindowWithLabel;
	BOOL mDisplayLabelText;
	BOOL mTestMCQ;
	int mTestMCQNumber;
	BOOL mDelayedMCQ;
	float mTestDifficulty;
	BOOL mShowBacktranslation;
	BOOL mInitialSlideshow;
	BOOL mAutoPlayMedia;
	BOOL mImageMCQ;
	int mMediaHideQuestion;
	int mTimer;
	float mTimerDuration;
	
	BOOL mTestOldWords;
	int mTestOldNumber;
	int mTestOldUnit;
	
	BOOL mTestLimit;
	int mTestLimitNumber;
	int mTestLimitWhat;

	BOOL mUseSpeechSynthesizer;
	NSString *mVoiceIdentifier;

    IBOutlet NSWindow *mMainWindow;
	BOOL mDisplayPages;
	
	BOOL mHasVisibleMedia;
	BOOL mHasVisibleSourceAudio;
	BOOL mHasVisibleTargetAudio;
	
	IBOutlet NSTableView *mLabelTableView;
    IBOutlet NSTableView *mWordTableView;
	IBOutlet NSOutlineView *mPageOutlineView;

    IBOutlet NSPopUpButton *mSourceLanguagePopUp;
    IBOutlet NSPopUpButton *mTargetLanguagePopUp;
    IBOutlet NSTextField *mSourceTextField;
    IBOutlet NSTextField *mTargetTextField;
    IBOutlet NSTextField *mCommentTextField;
	IBOutlet NSPopUpButton *mTestDirectionPopUp;

	IBOutlet NSView *mSourceInputView;
	IBOutlet NSView *mTargetInputView;
	IBOutlet NSView *mCommentInputView;
	IBOutlet NSView *mAboveInputView;
	
	int mMainTab;
	BOOL mEditingPreset;
	
	IBOutlet NSSplitView *mMainSplitView;
	IBOutlet NSView *mPresetView;
	IBOutlet NSTableView *mPresetTableView;
	IBOutlet NSView *mPresetEditView;
	IBOutlet NSView *mPresetSettingsView;
	
	IBOutlet NSSearchField *mSearchField;
	IBOutlet NSMenu *mSearchMenu;

	IBOutlet NSView *mPrintAccessoryView;

	NSString *mSearchString;
    NSTableColumn *mSortingColumn;
    BOOL mSortDescending;
	
	BOOL mTestIsRunning;
	ProVocTester *mTester;

    IBOutlet NSPanel *mInputPanel;
    IBOutlet NSTextField *mInputPromptTextField;
    IBOutlet NSTextField *mInputTextField;
    SEL mInputPanelCallbackSelector;

	IBOutlet NSView *mExportAccessoryView;
	IBOutlet NSView *mImportAccessoryView;
	
	ProVocActionController *mActionController;
	
	NSString *mFontFamilyName;
	
	NSArray *mLabels;
	BOOL mShowDoubles;
	
	NSMutableArray *mPresets;
	unsigned mIndexOfCurrentPresets;
	
	NSMutableArray *mHistories;
	IBOutlet ProVocHistoryView *mHistoryView;
	
	NSDictionary *mSubmissionInfo;
	
	BOOL mAutosaving;
	
	NSArray *mAllWordTableColumns;
	
	NSDate *mLastWidgetLogModificationDate;
	int mLinesReadInWidgetLog;
	ProVocHistory *mCurrentWidgetLogHistory;
	id mCurrentWidgetRepetitions;
}

-(NSWindow *)window;

-(void)setMainTab:(int)inTab;
-(void)setEditingPreset:(BOOL)inEdit;

@end

@interface ProVocDocument (Preferences)

-(void)getGlobalPreferencesFromDefaults;
-(void)getDefaultGlobalPreferencesFromDefaults;
-(void)setGlobalPreferencesToDefaults;

-(NSDictionary *)parameters;
-(void)setParameters:(NSDictionary *)inParameters;

@end

@interface ProVocDocument (Current)

+(void)setCurrentDocument:(ProVocDocument *)inDocument;
+(ProVocDocument *)currentDocument;
-(BOOL)isCurrentDocument;

@end

@interface ProVocDocument (Actions)

-(void)requestNewName:(NSString *)inPrompt defaultName:(NSString *)inDefaultName callbackSelector:(SEL)inCallbackSelector;
-(IBAction)newPage:(id)inSender;
-(IBAction)newChapter:(id)inSender;
-(IBAction)deletePage:(id)inSender;

-(IBAction)addNewWord:(id)inSender;

-(IBAction)search:(id)inSender;
-(IBAction)setSearchCategory:(id)inSender;
-(NSString *)searchCategoryForTag:(int)inTag;
-(void)setSpotlightSearch:(NSString *)inSearchString;

-(IBAction)startSlideshow:(id)inSender;
-(IBAction)startTest:(id)inSender;
-(void)testPanelDidClose;
-(void)testDidFinish;
-(BOOL)testIsRunning;

-(IBAction)printDocument:(id)inSender;
-(IBAction)printCards:(id)inSender;

-(IBAction)showGeneralPreferences:(id)inSender;

-(NSArray *)wordsToBeTested;

-(IBAction)selectView:(id)inSender;

@end

@interface ProVocDocument (ExternalActions)

-(IBAction)sourcePopUpAction:(id)inSender;
-(IBAction)targetPopUpAction:(id)inSender;

-(IBAction)import:(id)inSender;
-(IBAction)export:(id)inSender;

-(IBAction)submitDocument:(id)inSender;

@end

@interface ProVocDocument (NamePrompt)

-(void)openInputPanel:(NSString *)inPrompt defaultValue:(NSString *)inDefault;
-(IBAction)cancelInputPanel:(id)inSender;
-(IBAction)okInputPanel:(id)inSender;

@end

@interface ProVocDocument (Private)

-(void)setDirty:(BOOL)inFlag;
-(void)selectedWordsDidChange:(id)inSender;
-(void)documentParameterDidChange:(id)inSender;
-(void)selectedWordParameterDidChange:(id)inSender;

@end

@interface ProVocDocument (Settings)

-(int)numberOfRetries;
-(int)testDirection;
-(float)testDirectionProbability;
-(BOOL)testWordsToReview;
-(BOOL)testMarked;
-(NSString *)sourceLanguage;
-(NSString *)targetLanguage;
-(NSString *)sourceLanguageCaption;
-(NSString *)targetLanguageCaption;

@end

@interface ProVocDocument (History)

-(void)removeLastHistory;
-(void)addHistory:(id)inHistory;
-(IBAction)clearHistory:(id)inSender;

@end

@interface ProVocDocument (Undo)

-(void)willChangeWord:(ProVocWord *)inWord;
-(void)didChangeWord:(ProVocWord *)inWord;
-(void)willChangeSource:(ProVocSource *)inSource;
-(void)didChangeSource:(ProVocSource *)inSource;
-(void)willChangeData;
-(void)didChangeData;
-(void)willChangeHistories;
-(void)didChangeHistories;
-(void)willChangePresets;
-(void)didChangePresets;
-(void)willChangeLanguages;
-(void)didChangeLanguages;
@end

@interface ProVocDocument (FontsAndSizes)

-(NSString *)sourceFontFamilyName;
-(float)sourceFontSize;
-(NSWritingDirection)sourceWritingDirection;
-(NSString *)targetFontFamilyName;
-(float)targetFontSize;
-(NSWritingDirection)targetWritingDirection;
-(NSString *)commentFontFamilyName;
-(float)commentFontSize;
-(NSWritingDirection)commentWritingDirection;
-(float)sourceTestFontSize;
-(float)targetTestFontSize;
-(float)commentTestFontSize;

@end

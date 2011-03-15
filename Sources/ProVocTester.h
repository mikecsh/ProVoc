//
//  TestController.h
//  ProVoc
//
//  Created by bovet on Sat Feb 08 2003.
//  Copyright (c) 2003 Arizona Software. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "ProVocDocument.h"
#import "ProVocWord.h"
#import "ProVocMCQView.h"
#import "ProVocImageView.h"
#import "ProVocMovieView.h"
#import "ProVocResultView.h"

#import <QTKit/QTKit.h>

#define PVDimTestBackground @"dimTestBackground"
#define PVFullScreenWithMenuBar @"fullScreenWithMenuBar"
#define PVTestBackgroundColor @"testBackgroundColor"

#define PVMarkWrongWords @"markWrongWords"
#define PVLabelForWrongWords @"labelForWrongWords"
#define PVSlideShowWithWrongWords @"slideShowWithWrongWords"

#define PVLearnedConsecutiveRepetitions @"learnedConsecutiveRepetitions"
#define PVLearnedDistractInterval @"learnedDistractInterval"

#define PVReviewLearningFactor @"reviewLearningFactor"
#define PVReviewTrainingFactor @"reviewTrainingFactor"

#define PVBackTranslationWithAllWords @"fullBackTranslation"

@class ProVocTimer;

@interface ProVocTester : NSWindowController {
    ProVocDocument *mProVocDocument;

        // Test du vocabulaire
    IBOutlet NSPanel *mTestPanel;
    IBOutlet NSPanel *mMCQTestPanel;
    IBOutlet NSTextField *mAnswerTextField;
	IBOutlet ProVocMCQView *mMCQView;
	IBOutlet NSView *mMoreResultParameters;
    
	NSMutableArray *mAllWords;
	NSArray *mTestedWords;
    NSMutableArray *mWordsArray;
    NSMutableArray *mWrongWordsArray;
	NSMutableArray *mUntestedWords;
    ProVocWord *mCurrentWord;
    
    int mTestWordMax;
    int mTestWordCurrent;
    short mWrongRetry;
	BOOL mShowBacktranslation;
	BOOL mAutoPlayMedia;
	BOOL mImageMCQ;
	int mMediaHideQuestion;
    
	BOOL mDontShuffleWords;
    int mMaxRetryCount;
	
	BOOL mAnswersCaseSensitive[2];
	BOOL mAnswersAccentSensitive[2];
	BOOL mAnswersPunctuationSensitive[2];
	BOOL mAnswersSpaceSensitive[2];
	NSMutableArray *mDeterminents[2];
        
        // Résultat du test
    IBOutlet NSPanel *mResultPanel;
	IBOutlet ProVocResultView *mResultView;
    IBOutlet NSButton *mRetryButton;
    IBOutlet NSButton *mTerminateButton;
	
		// Labels
	IBOutlet NSPopUpButton *mLabelPopUp1;
	IBOutlet NSPopUpButton *mLabelPopUp2;
	IBOutlet NSPopUpButton *mLabelPopUp3;
	
	IBOutlet NSSplitView *mSplitView;
	IBOutlet NSSplitView *mMCQSplitView;
	
	ProVocTimer *mTimer;
	BOOL mTimerDidElapse;

	IBOutlet NSPanel *mNotePanel;
	NSString *mSourceOfNoteWords;
	NSMutableArray *mNoteWords;

	NSString *mEquivalentAnswer;

    int mDirection;
	int mRequestedDirection;
	float mDirectionProbability;
    int mMode;
	
	int mLateComments;
	int mDisplayLabels;
	BOOL mColorWindowWithLabel;
	BOOL mShowingLateComment;
	BOOL mShowingFullAnswer;
	BOOL mShowingCorrectAnswer;
	BOOL mHidingQuestionText;
	BOOL mShowingQuestionMedia;
	
	BOOL mDisableTestButtons;
	
	int mIndexOfLastWord;
	
	int mWholeRepetition;
	NSMutableArray *mRepetitions;
	NSMutableSet *mCorrectlyAnswered;
	
	NSMutableArray *mLearnedWords;
	NSMutableArray *mLearnedWordsInfo;
	
	NSDate *mHistoryStart;
	NSMutableArray *mHistory;
	BOOL mReplaceLastHistory;
	BOOL mFreezeHistory;
	BOOL mScreenDimmed;
	
	id mLastMovie;
	BOOL mMaskMedia;
	
	BOOL mUseSpeechSynthesizer;
	NSString *mVoiceIdentifier;
	NSSpeechSynthesizer *mSpeechSynthesizer;
	int mSpeechSynthesizerState;
	
	BOOL mFinishing;
}

+ (NSArray *)currentTesters;
- (BOOL)handleKeyDownEvent:(NSEvent *)inEvent;

- (id)initWithDocument:(ProVocDocument*)document;
- (void)beginTestWithWords:(NSArray*)words parameters:(id)inParameters sourceLanguage:(NSString *)inSourceLanguage targetLanguage:(NSString *)inTargetLanguage;
- (void)resumeTestWithParameters:(id)inParameters;
- (void)terminateTest:(BOOL)inFinal;
- (void)updateDirection;
@end

@interface ProVocTester (TestPanel)
- (void)openTestPanel;
- (IBAction)cancelTestPanel:(id)sender;
- (IBAction)verifyTestPanel:(id)sender;
- (IBAction)giveAnswerTestPanel:(id)sender;
- (IBAction)acceptAnswer:(id)sender;
- (IBAction)pauseTestPanel:(id)sender;
- (NSString *)verifyTitle;

-(NSString *)genericAnswerString:(NSString *)inAnswer;
-(id)fullGenericAnswerString:(NSString *)inAnswer;
-(NSString *)question;
-(NSString *)comment;
-(BOOL)applyRandomWord;
-(void)adjustViews;

-(BOOL)isGenericString:(id)inAnswer equalToString:(NSString *)inString;
@end

@interface ProVocTester (ResultPanel)
- (void)openResultPanel;
- (IBAction)terminateResultPanel:(id)sender;
- (IBAction)retryResultPanel:(id)sender;
@end

@interface ProVocTester (Private)
- (void)setWords:(NSArray *)inWords;
- (ProVocWord *)chooseRandomWord;
- (NSWindow *)modalWindow;
@end

@interface ProVocTester (Note)
- (void)setNotesForAnswer:(NSString *)inString;
- (void)showNoteForAnswer:(NSString *)inString;
- (BOOL)hideNote;
@end

@interface NSString (ProVocTester)

-(NSArray *)synonyms;

@end

@interface ProVocTestPanel : NSPanel {
	IBOutlet ProVocTester *mTester;
}

@end

@interface ProVocTester (History)

-(void)historyStart;
-(void)historySetRepetition:(int)inRepetition ofWord:(ProVocWord *)inWord;
-(void)historyCommit;

@end

@interface ProVocTester (Image)

-(NSImage *)image;

@end

@interface ProVocTester (Movie)

-(id)movie;

@end

@interface ProVocTester (Audio)

-(BOOL)canPlayQuestionAudio;
-(BOOL)canPlayAnswerAudio;
-(IBAction)playQuestionAudio:(id)inSender;
-(IBAction)playAnswerAudio:(id)inSender;

@end

@interface NSScreen (ProVocTester)

+(void)dimScreensHidingMenuBar:(BOOL)inHideMenuBar;
+(void)undimScreens;

@end

@interface ProVocBackTranslationPanel : NSPanel

@end

@interface ProVocTesterImageView : ProVocImageView

@end

@interface ProVocTesterMovieView : ProVocMovieView

@end

@interface ProVocTesterMediaView : NSView {
	IBOutlet NSView *mLeftView;
	IBOutlet NSView *mRightView;
}

@end

@interface ProVocMovieViewContainer : NSView {
	IBOutlet id mTester;
	id mMovieView;
}

-(IBAction)play:(id)inSender;
-(IBAction)fullScreen:(id)inSender;

@end

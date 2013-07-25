//
//  ProVocTester.m
//  ProVoc
//
//  Created by bovet on Sat Feb 08 2003.
//  Copyright (c) 2003 Arizona Software. All rights reserved.
//

#import "ProVocTester.h"
#import "ProVocPreferences.h"
#import "ProVocDocument+Lists.h"
#import "ProVocDocument+Slideshow.h"
#import "ProVocHistory.h"
#import "ProVocInspector.h"
#import "ProVocBackground.h"
#import "ProVocTimer.h"

#import <Carbon/Carbon.h>
#import <QTKit/QTKit.h>

#import "WindowExtensions.h"
#import "StringExtensions.h"
#import "ArrayExtensions.h"

#define OK 1
#define CANCEL 0
#define PAUSE 2

enum {
	kBackgroundQuestion = 1 << 1,
	kBackgroundAnswer = 1 << 2,
	
	kBackgroundResults = 1 << 10,
	kBackgroundNewQuestion = 1 << 11,
	kBackgroundCorrectAnswer = 1 << 12,
	kBackgroundWrongAnswer = 1 << 13
};

@interface NSView (Media)

-(void)adjustSize;
-(float)preferredWidthForHeight:(float)inHeight;
-(void)stopMedia;

@end

@interface ProVocWord (ProVocTester)

-(ProVocWord *)word;
-(void)decrementWrong;

@end

@implementation ProVocWord (ProVocTester)

-(ProVocWord *)word
{
	return self;
}

-(void)decrementWrong
{
    mWrong--;
}

@end

@interface ProVocSynonymWord : NSObject {
	ProVocWord *mWord;
	NSString *mSourceWord;
	NSString *mTargetWord;
}

-(id)initWithWord:(ProVocWord *)inWord;
-(ProVocWord *)word;
-(int)direction;
-(void)setSourceWord:(NSString *)inSource;
-(void)setTargetWord:(NSString *)inTarget;

@end

@interface ProVocDirectedWord : NSObject {
	ProVocWord *mWord;
	int mDirection;
}

-(id)initWithWord:(ProVocWord *)inWord direction:(int)inDirection;
-(ProVocWord *)word;
-(int)direction;

@end

@interface ProVocDocument (TestDifficulty)

-(float)testDifficulty;
-(void)setTestDifficulty:(float)inTestDifficulty;

@end

@interface ProVocTester (MorePrivate)

-(void)savePanelLayout;

-(BOOL)shouldHideLabel;
-(NSPanel *)testPanel;

-(void)testEnded;
-(void)finishTest;

-(NSString *)questionAudioKey;
-(NSString *)answerAudioKey;

-(void)updateBackground:(int)inWhat;

-(void)hideAnswer;
-(BOOL)canGiveAnswer;
-(BOOL)displayCorrectAnswer;
-(NSString *)correctAnswer;
-(void)setDisplayCorrectAnswer:(BOOL)inDisplay;
-(int)indexForRepetition:(int *)outRepetition ofWord:(id)inWord;
-(void)historySetRepetition:(int)inRepetition ofWord:(ProVocWord *)inWord;

-(void)stopSpeaking;

-(BOOL)isGenericString:(id)inString equalToWord:(NSString *)inWord;

@end

@implementation ProVocTester

+(void)initialize
{
}

+(NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSMutableSet *affectedValuesKeyPaths = [NSMutableSet set];
    
    if ([key isEqualToString:@"progress"])
        [affectedValuesKeyPaths addObjectsFromArray:@[@"progressMin",@"progressMax",@"progressValue",@"progressTitle"]];
    else if ([key isEqualToString:@"displayCorrectAnswer"])
        [affectedValuesKeyPaths addObjectsFromArray:@[@"canGiveAnswer",@"verifyTitle",@"correctAnswer",@"hideComment", @"hideLabel"]];
    else if ([key isEqualToString:@"audio"])
        [affectedValuesKeyPaths addObjectsFromArray:@[@"canPlayQuestionAudio",@"canPlayAnswerAudio",@"questionAudioImage",@"answerAudioImage"]];
    else if ([key isEqualToString:@"noteWords"])
        [affectedValuesKeyPaths addObjectsFromArray:@[@"maxNoteIndex",@"multipleNote"]];
    else if ([key isEqualToString:@"font"])
        [affectedValuesKeyPaths addObjectsFromArray:@[@"questionFontSize",@"answerFontSize",@"questionWritingDirection",@"answerWritingDirection"]];
    else if ([key isEqualToString:@"commentFont"])
        [affectedValuesKeyPaths addObjectsFromArray:@[@"sourceFontSize",@"targetFontSize",@"commentFontSize",@"sourceWritingDirection",@"targetWritingDirection",@"commentWritingDirection"]];
    else if ([key isEqualToString:@"movie"])
        [affectedValuesKeyPaths addObject:@"nonNilMovie"];
    else if ([key isEqualToString:@"hideQuestion"])
        [affectedValuesKeyPaths addObjectsFromArray:@[@"question", @"canGiveAnswer", @"verifyTitle"]];
    else if ([key isEqualToString:@"flagged"])
        [affectedValuesKeyPaths addObject:@"labelIndex"];
    else if ([key isEqualToString:@"canGiveAnswer"])
        [affectedValuesKeyPaths addObject:@"verifyTitle"];
    else if ([key isEqualToString:@"hideComment"])
        [affectedValuesKeyPaths addObjectsFromArray:@[@"hideLabel", @"canGiveAnswer", @"verifyTitle"]];

    return affectedValuesKeyPaths;
}



static NSMutableArray *sCurrentTesters = nil;

+(NSArray *)currentTesters
{
	return sCurrentTesters;
}

-(BOOL)handleKeyDownEvent:(NSEvent *)inEvent
{
	if (([inEvent modifierFlags] & (NSCommandKeyMask | NSControlKeyMask)) != 0)
		return NO;
	if (![mProVocDocument isCurrentDocument])
		return NO;
	switch ([inEvent keyCode]) {
		case 122: // F1
			[self playQuestionAudio:nil];
			return YES;
		case 120: // F2
			[self playAnswerAudio:nil];
			return YES;
		case 99: // F3
		{
			ProVocImageView *imageView = (ProVocImageView *)[[[self testPanel] contentView] subviewOfClass:[ProVocImageView class]];
			if (![imageView isHidden]) {
				[imageView displayFullImage:nil];
				return YES;
			}
			break;
		}
		case 118: // F4
		{
			ProVocMovieView *movieView = (ProVocMovieView *)[[[self testPanel] contentView] subviewOfClass:[ProVocMovieView class]];
			if (![movieView isHidden]) {
				if (([inEvent modifierFlags] & (NSAlternateKeyMask | NSShiftKeyMask)) == 0)
					[movieView play:nil];
				else
					[movieView fullScreen:nil];
				return YES;
			}
			break;
		}
		default:
			break;
	}
	
	if ([self displayCorrectAnswer]) {
		NSString *c = [inEvent charactersIgnoringModifiers];
		if ([c isCaseInsensitiveLike:@"y"]) {
			[self verifyTestPanel:[NSNumber numberWithBool:YES]];
			return YES;
		}
		if ([c isCaseInsensitiveLike:@"n"]) {
			[self verifyTestPanel:[NSNumber numberWithBool:NO]];
			return YES;
		}
	}
	
	return NO;
}

-(id)initWithDocument:(ProVocDocument *)inDocument
{
    if (self = [super initWithWindowNibName:@"ProVocTester"]) {
        [self loadWindow];

        mProVocDocument = inDocument;
        mWrongWordsArray = nil;

        mWordsArray = [[NSMutableArray alloc] init];

        mMaxRetryCount = [inDocument numberOfRetries];

		NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
		NSMenu *allMarksMenu = [[NSMenu alloc] initWithTitle:@""];

		NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Flagged Word Title", @"") action:nil keyEquivalent:@""] autorelease];
		[item setImage:[NSImage imageNamed:@"flagged"]];
		[allMarksMenu addItem:item];

		int label;
		for (label = 0; label <= 9; label++) {
			item = [[[NSMenuItem alloc] initWithTitle:[mProVocDocument stringForLabel:label] action:nil keyEquivalent:[NSString stringWithFormat:@"%i", label]] autorelease];
			[item setImage:[mProVocDocument imageForLabel:label]];
			[menu addItem:item];

			item = [[[NSMenuItem alloc] initWithTitle:[mProVocDocument stringForLabel:label] action:nil keyEquivalent:@""] autorelease];
			[item setImage:[mProVocDocument imageForLabel:label]];
			[allMarksMenu addItem:item];
		}

		[mLabelPopUp1 setMenu:menu];
		[[mLabelPopUp1 cell] setArrowPosition:NSPopUpNoArrow];
		[mLabelPopUp2 setMenu:allMarksMenu];
		[mLabelPopUp3 setMenu:menu];
		[[mLabelPopUp3 cell] setArrowPosition:NSPopUpNoArrow];
		
		[self willChangeValueForKey:@"commentFont"];
		[self didChangeValueForKey:@"commentFont"];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(soundDidStartOrStop:) name:ProVocSoundDidStartPlayingNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(soundDidStartOrStop:) name:ProVocSoundDidStopPlayingNotification object:nil];
    }
    return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[mAllWords release];
	[mTestedWords release];
	[mCurrentWord release];
    [mWordsArray release];
    [mWrongWordsArray release];
	[mNoteWords release];
	[mSourceOfNoteWords release];
	[mEquivalentAnswer release];
	[mDeterminents[0] release];
	[mDeterminents[1] release];
	[mRepetitions release];
	[mCorrectlyAnswered release];
	[mUntestedWords release];
	[mHistoryStart release];
	[mHistory release];
	[mLastMovie release];
	[mTimer release];
	[mSpeechSynthesizer release];
	[mLearnedWords release];
	[mLearnedWordsInfo release];
    [super dealloc];
}

-(void)setLanguageSettings:(NSDictionary *)inSettings forDirection:(int)inDirection
{
	mAnswersCaseSensitive[inDirection] = mAnswersAccentSensitive[inDirection] =
		mAnswersPunctuationSensitive[inDirection] = mAnswersSpaceSensitive[inDirection] = YES;
	[mDeterminents[inDirection] release];
	mDeterminents[inDirection] = nil;
	if (inSettings) {
		mAnswersCaseSensitive[inDirection] = [[inSettings objectForKey:PVCaseSensitive] boolValue];
		mAnswersAccentSensitive[inDirection] = [[inSettings objectForKey:PVAccentSensitive] boolValue];
		mAnswersPunctuationSensitive[inDirection] = [[inSettings objectForKey:PVPunctuationSensitive] boolValue];
		mAnswersSpaceSensitive[inDirection] = [[inSettings objectForKey:PVSpaceSensitive] boolValue];
		NSEnumerator *enumerator = [[[inSettings objectForKey:@"FacultativeDeterminents"] componentsSeparatedByString:@","] objectEnumerator];
		NSString *determinent;
		while (determinent = [enumerator nextObject]) {
			if (!mDeterminents[inDirection])
				mDeterminents[inDirection] = [[NSMutableArray alloc] initWithCapacity:0];
			[mDeterminents[inDirection] addObject:[determinent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
		}
	}
}

-(void)setLanguage:(NSString *)inLanguage forDirection:(int)inDirection
{
	NSDictionary *languages = [[NSUserDefaults standardUserDefaults] objectForKey:PVPrefsLanguages];
    NSEnumerator *enumerator = [[languages objectForKey:@"Languages"] objectEnumerator];
    NSDictionary *description;
    while (description = [enumerator nextObject])
		if ([inLanguage isEqual:[description objectForKey:@"Name"]])
			break;
	[self setLanguageSettings:description forDirection:inDirection];
}

-(int)mode
{
	return mMode;
}

int SORT_BY_NUMBER(id left, id right, void *info)
{
	int nA = [left number];
	int nB = [right number];
	if (nA == nB)
		return 0;
	else if (nA < nB)
		return -1;
	else
		return 1;
}

-(void)shuffleWords
{
	if (mDontShuffleWords) {
		[mWordsArray setArray:[mWordsArray sortedArrayUsingFunction:SORT_BY_NUMBER context:nil]];
		return;
	}
	[mWordsArray setArray:[mWordsArray shuffledArray]];
	ProVocWord *previous = nil;
	ProVocWord *word = nil;
	int i, n = [mWordsArray count];
	for (i = 0; i < n; i++) {
		previous = word;
		word = [[mWordsArray objectAtIndex:i] word];
		if ([previous isEqual:word]) {
			if (i < n - 1)
				[mWordsArray exchangeObjectAtIndex:i withObjectAtIndex:i + 1];
			else
				[mWordsArray exchangeObjectAtIndex:i - 1 withObjectAtIndex:0];
			word = [[mWordsArray objectAtIndex:i] word];
		}
	}
}

-(void)setWords:(NSArray *)inWords
{
	[mAllWords release];
	mAllWords = [inWords copy];
	
	if (mRequestedDirection == 3) {
		NSEnumerator *enumerator = [inWords objectEnumerator];
		ProVocWord *word;
		while (word = [enumerator nextObject]) {
			ProVocDirectedWord *directedWord = [[ProVocDirectedWord alloc] initWithWord:word direction:0];
			[mWordsArray addObject:directedWord];
			[directedWord release];
			directedWord = [[ProVocDirectedWord alloc] initWithWord:word direction:1];
			[mWordsArray addObject:directedWord];
			[directedWord release];
		}
	} else
		[mWordsArray setArray:inWords];

	[mTestedWords release];
	mTestedWords = [mWordsArray copy];
	
    if ([[NSUserDefaults standardUserDefaults] boolForKey:PVPrefsUseSynonymSeparator] &&
		[[NSUserDefaults standardUserDefaults] boolForKey:PVPrefTestSynonymsSeparately]) {
		// Split synonyms
		NSMutableArray *synonyms = [NSMutableArray array];
		NSEnumerator *enumerator = [mWordsArray reverseObjectEnumerator];
		id word;
		while (word = [enumerator nextObject]) {
			int direction = mRequestedDirection;
			if (direction == 3)
				direction = [word direction];
			if (direction < 2) {
				id question = !direction ? [word sourceWord] : [word targetWord];
				NSArray *questionSynonyms = [question synonyms];
				if ([questionSynonyms count] > 1) {
					NSEnumerator *enumerator = [questionSynonyms objectEnumerator];
					NSString *synonym;
					while (synonym = [enumerator nextObject]) {
						ProVocWord *newWord = [[ProVocSynonymWord alloc] initWithWord:word];
						if (!direction)
							[newWord setSourceWord:synonym];
						else
							[newWord setTargetWord:synonym];
						[synonyms addObject:newWord];
						[newWord release];
					}
					[mWordsArray removeObjectIdenticalTo:word];
				}
			}
		}
		[mWordsArray addObjectsFromArray:synonyms];
	}

	[self shuffleWords];
}

-(void)updateWindowBackgroundColor
{
	NSColor *color = nil;
	if (![self shouldHideLabel] && mColorWindowWithLabel)
		color = [mProVocDocument colorForLabel:[mCurrentWord label]];
	[[[self testPanel] contentView] setColor:color];
}

-(void)updateDirection
{
	[self willChangeValueForKey:@"hideComment"];
	mDirection = mRequestedDirection;
	if (mDirection == 2) {
		if (rand() % 100 < mDirectionProbability * 100)
			mDirection = 1;
		else
			mDirection = 0;
	}
	[self didChangeValueForKey:@"hideComment"];
	[self updateWindowBackgroundColor];
}

-(void)restartTest
{	
    [mWrongWordsArray release];    
    mWrongWordsArray = [[NSMutableArray alloc] init];
	[mCorrectlyAnswered release];
	mCorrectlyAnswered = [[NSMutableSet alloc] initWithCapacity:0];
    
	[self willChangeValueForKey:@"progress"];
	[self willChangeValueForKey:@"difficulty"];
    mTestWordMax = [mWordsArray count];
    mTestWordCurrent = 0;
	[self didChangeValueForKey:@"progress"];
	[self didChangeValueForKey:@"difficulty"];
    
	[self willChangeValueForKey:@"displayCorrectAnswer"];
	mShowingCorrectAnswer = NO;
	[self didChangeValueForKey:@"displayCorrectAnswer"];
	[self hideAnswer];

	[self flagsChanged:[NSApp currentEvent]];
    [self applyRandomWord];
}

-(void)updateSpeechParameters:(id)inParameters
{
	[self willChangeValueForKey:@"audio"];
	mUseSpeechSynthesizer = [[inParameters objectForKey:@"useSpeechSynthesizer"] boolValue];
	NSString *voiceIdentifier = [inParameters objectForKey:@"voiceIdentifier"];
	if (![mVoiceIdentifier isEqual:voiceIdentifier]) {
		[mVoiceIdentifier release];
		mVoiceIdentifier = [voiceIdentifier retain];
		[mSpeechSynthesizer release];
		mSpeechSynthesizer = nil;
	}
	[self didChangeValueForKey:@"audio"];
	
}

-(void)beginTestWithWords:(NSArray*)words parameters:(id)inParameters sourceLanguage:(NSString *)inSourceLanguage targetLanguage:(NSString *)inTargetLanguage
{
	if ([[inParameters objectForKey:@"initialSlideshow"] boolValue]) {
		NSMutableArray *newWords = [NSMutableArray array];
		NSEnumerator *enumerator = [words objectEnumerator];
		ProVocWord *word;
		while (word = [enumerator nextObject])
			if ([word right] <= 0)
				[newWords addObject:word];
		if ([newWords count] > 0) {
			[NSScreen dimScreensHidingMenuBar:YES];
			mScreenDimmed = YES;
			[mProVocDocument slideshowWithWords:newWords];
		}
	}
	
	[self historyStart];
	mIndexOfLastWord = -1;
    mRequestedDirection = [[inParameters objectForKey:@"testDirection"] intValue];
	mDirectionProbability = [[inParameters objectForKey:@"testDirectionProbability"] floatValue];
    mDontShuffleWords = [[inParameters objectForKey:@"dontShuffleWords"] intValue];
	mAutoPlayMedia = [[inParameters objectForKey:@"autoPlayMedia"] boolValue];
	mImageMCQ = [[inParameters objectForKey:@"imageMCQ"] boolValue] && [[inParameters objectForKey:@"testMCQ"] boolValue];
	mMediaHideQuestion = [[inParameters objectForKey:@"mediaHideQuestion"] intValue];
	[self willChangeValueForKey:@"mode"];
	[self willChangeValueForKey:@"hideComment"];
    mMode = [[inParameters objectForKey:@"testKind"] intValue];
	if (mMode == 1 && mRequestedDirection == 3) {
		mRequestedDirection = 2;
		mDirectionProbability = 0.5;
	}
	[self updateDirection];

	[self updateSpeechParameters:inParameters];
	
	[self didChangeValueForKey:@"mode"];
	[self didChangeValueForKey:@"hideComment"];
	[self updateWindowBackgroundColor];
	[self setWords:words];
	[self setLanguage:inSourceLanguage forDirection:1];
	[self setLanguage:inTargetLanguage forDirection:0];
	
	if ([[inParameters objectForKey:@"timer"] intValue] > 0) {
		mTimer = [[ProVocTimer alloc] init];
		if ([[inParameters objectForKey:@"timer"] intValue] == 2)
			[mTimer setRemainingTime:[[inParameters objectForKey:@"timerDuration"] floatValue]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(timerDidElapse:) name:ProVocTimerRemainingTimeDidElapseNotification object:mTimer];
	}
	
	[self restartTest];
	[self resumeTestWithParameters:inParameters];
}

-(void)setPopUp:(NSPopUpButton *)inPopUp width:(float)inWidth
{
	NSRect frame = [inPopUp frame];
	float dx = inWidth - frame.size.width;
	if (dx == 0)
		return;
	frame.origin.x -= dx;
	frame.size.width = inWidth;
	[inPopUp setFrame:frame];
	
	float ymin = NSMinY(frame);
	float ymax = NSMaxY(frame);
	NSEnumerator *enumerator = [[[inPopUp superview] subviews] objectEnumerator];
	NSView *view;
	while (view = [enumerator nextObject]) {
		frame = [view frame];
		if (view != inPopUp && NSMaxY(frame) > ymin && NSMinY(frame) < ymax) {
			frame.origin.x -= dx;
			[view setFrameOrigin:frame.origin];
		}
	}
}

-(void)resumeTestWithParameters:(id)inParameters
{
	float width = [[inParameters objectForKey:@"displayLabelText"] boolValue] ? 150 : 30;
	[self setPopUp:mLabelPopUp1 width:width];
	[self setPopUp:mLabelPopUp3 width:width];
	
	[self flagsChanged:[NSApp currentEvent]];
	
	[self updateSpeechParameters:inParameters];

	[self willChangeValueForKey:@"hideComment"];
	mLateComments = [[inParameters objectForKey:@"lateComments"] intValue];
	mDisplayLabels = [[inParameters objectForKey:@"displayLabels"] intValue];
	mColorWindowWithLabel = [[inParameters objectForKey:@"colorWindowWithLabel"] boolValue];
	[self didChangeValueForKey:@"hideComment"];
	[self updateWindowBackgroundColor];
	mShowBacktranslation = [[inParameters objectForKey:@"showBacktranslation"] boolValue];
	mAutoPlayMedia = [[inParameters objectForKey:@"autoPlayMedia"] boolValue];
	mImageMCQ = [[inParameters objectForKey:@"imageMCQ"] boolValue] && [[inParameters objectForKey:@"testMCQ"] boolValue];
	mMediaHideQuestion = [[inParameters objectForKey:@"mediaHideQuestion"] intValue];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:PVDimTestBackground]) {
		[NSScreen dimScreensHidingMenuBar:![[NSUserDefaults standardUserDefaults] boolForKey:PVFullScreenWithMenuBar]];
		[[ProVocBackground sharedBackground] display];
	}
	if (mScreenDimmed) {
		mScreenDimmed = NO;
		[NSScreen undimScreens];
	}
	if (!sCurrentTesters)
		sCurrentTesters = [[NSMutableArray array] retain];
	[sCurrentTesters addObject:self];
	[mTimer start];
    [self openTestPanel];
}

-(void)terminateTest:(BOOL)inFinal
{
	[sCurrentTesters removeObject:self];
	[self historyCommit];
	[mTimer stop];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:PVDimTestBackground]) {
		[[ProVocBackground sharedBackground] hide];
		[NSScreen undimScreens];
	}
	[mProVocDocument willChangeValueForKey:@"canResumeTest"];
    [mProVocDocument testPanelDidClose];
	if (inFinal)
	    [mProVocDocument testDidFinish];
	else
		mReplaceLastHistory = YES;
	[mProVocDocument didChangeValueForKey:@"canResumeTest"];
}

-(BOOL)waitForAnswerBeforeTimerElapse
{
	return YES;
}

-(void)timerDidElapse:(NSNotification *)inNotification
{
	if ([self waitForAnswerBeforeTimerElapse] && [self canGiveAnswer]) {
		mTimerDidElapse = YES;
		return;
	}
	
	NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Timer Did Elapse Title", @"")
								defaultButton:NSLocalizedString(@"Timer Did Elapse Finish Button", @"")
								alternateButton:NSLocalizedString(@"Timer Did Elapse 1' Button", @"")
								otherButton:NSLocalizedString(@"Timer Did Elapse Discard Button", @"")
								informativeTextWithFormat:NSLocalizedString(@"Timer Did Elapse Message", @"")];
	[[alert window] setLevel:NSStatusWindowLevel];
	int result = [alert runModal];
	switch (result) {
		case NSAlertDefaultReturn:
			[self finishTest];
			break;
		case NSAlertAlternateReturn:
			[mTimer addRemainingTime:60];
			break;
		case NSAlertOtherReturn:
			break;
	}
}

@end

@implementation ProVocTester (TestPanel)

-(IBAction)setLabel:(id)inSender
{
	int label = [inSender tag];
	[self willChangeValueForKey:@"labelIndex"];
	[mCurrentWord setLabel:label];
	[self didChangeValueForKey:@"labelIndex"];
}

-(BOOL)flagged
{
	return [mCurrentWord mark] > 0;
}

-(void)setFlagged:(BOOL)inFlagged
{
	[mCurrentWord setMark:inFlagged ? 1 : 0];
}

-(int)labelIndex
{
	return [mCurrentWord label];
}

-(void)setLabelIndex:(int)inLabel
{
	[mCurrentWord setLabel:inLabel];
}

-(NSString *)question
{
	if (mHidingQuestionText || mMediaHideQuestion == 2 && ([self canPlayQuestionAudio] || [self image] || [self movie]))
		return @"";
    return !mDirection ? [mCurrentWord sourceWord] : [mCurrentWord targetWord];
}

-(NSString *)answer
{
    return mDirection ? [mCurrentWord sourceWord] : [mCurrentWord targetWord];
}

-(NSString *)comment
{
	return [mCurrentWord comment] ? [mCurrentWord comment] : @"";
}

static float sMinDifficulty, sDifficultyFactor, sDifficultyTemperature;

-(float)testProbabilyForWordAtIndex:(int)inIndex
{
	float difficulty = [[mWordsArray objectAtIndex:inIndex] difficulty];
	return exp(sDifficultyTemperature * (difficulty - sMinDifficulty) * sDifficultyFactor);
}

-(float)difficulty
{
	return [mProVocDocument testDifficulty];
}

-(void)setDifficulty:(float)inDifficulty
{
	[mProVocDocument setTestDifficulty:inDifficulty];
}

-(float)progressMin
{
	return 1;
}

-(float)progressMax
{
	return mTestWordMax;
}

-(float)progressValue
{
	return mTestWordCurrent;
}

-(NSString *)progressTitle
{
	return [NSString stringWithFormat:@"%i / %i", mTestWordCurrent, mTestWordMax];
}

-(NSString *)translationCaption
{
	NSString *caption = [[NSUserDefaults standardUserDefaults] valueForKey:@"translationCaption"];
	if ([caption length] == 0)
		caption = NSLocalizedString(@"Translation Caption", @"");
	return caption;
}

-(void)prepareTestProbabilities
{
	float minDifficulty = 0, maxDifficulty = 0;
	BOOL first = YES;
	NSEnumerator *enumerator = [mWordsArray objectEnumerator];
	ProVocWord *word;
	while (word = [enumerator nextObject]) {
		float difficulty = [word difficulty];
		if (first || difficulty > maxDifficulty)
			maxDifficulty = difficulty;
		if (first || difficulty < minDifficulty)
			minDifficulty = difficulty;
		first = NO;
	}
	
	sMinDifficulty = minDifficulty;
	sDifficultyFactor = maxDifficulty == minDifficulty ? 1.0 : 1.0 / (maxDifficulty - minDifficulty);
	
	sDifficultyTemperature = [self difficulty] * 2 * log(2);
}

-(ProVocWord *)chooseRandomWord
{
	int randomIndex = 0;
	if (mMode == 0 || mMode == 2)
		randomIndex = 0;
	if (mMode == 1) {
		[self prepareTestProbabilities];
		
		float Total = 0;
		int i, nb = [mWordsArray count];
		for (i = 0; i < nb; i++)
			if (i != mIndexOfLastWord)
				Total += [self testProbabilyForWordAtIndex:i];

		do {
			float total = Total;
			total *= (float)rand() / RAND_MAX;
			i = -1;
			do {
				++i;
				if (i != mIndexOfLastWord)
					total -= [self testProbabilyForWordAtIndex:i];
			} while (total > 0);
		} while (nb > 1 && mIndexOfLastWord == i);
		mIndexOfLastWord = randomIndex = i;
	}
	
	id word = [mWordsArray objectAtIndex:randomIndex];
	if ([word respondsToSelector:@selector(direction)])
		mDirection = [(ProVocDirectedWord *)word direction];
	return word;
}

-(void)adjustViews
{
	[[[self testPanel] contentView] adjustSize];
}

-(void)stopMedia
{
	[self stopSpeaking];
	[[ProVocInspector sharedInspector] stopPlayingSound];
	[[[self testPanel] contentView] stopMedia];
}

-(void)displayQuestionMedia
{
	mShowingQuestionMedia = YES;
	if (mMediaHideQuestion != 4 && ([self canPlayQuestionAudio] || [self image] || [self movie])) {
		mHidingQuestionText = mMediaHideQuestion == 1;
		if (mAutoPlayMedia) {
			NSArray *modes = [NSArray arrayWithObjects:NSDefaultRunLoopMode, NSModalPanelRunLoopMode, nil];
			[self performSelector:@selector(playQuestionAudio:) withObject:nil afterDelay:0.0 inModes:modes];
			if ([NSApp hasQTKit]) {
				QTMovieView *movieView = (QTMovieView *)[[[self testPanel] contentView] subviewOfClass:[QTMovieView class]];
				[movieView performSelector:@selector(playIfVisible:) withObject:nil afterDelay:0.0 inModes:modes];
			}
		}
	}
}

-(BOOL)applyRandomWord
{
	[self updateDirection];
	[self stopMedia];
	
    if ([mWordsArray count] > 0) {
		[self willChangeValueForKey:@"question"];
		[self willChangeValueForKey:@"comment"];
		[self willChangeValueForKey:@"flagged"];
		[self willChangeValueForKey:@"hideQuestion"];
		[self willChangeValueForKey:@"hideComment"];
		[self willChangeValueForKey:@"font"];
		[self willChangeValueForKey:@"audio"];
		[self willChangeValueForKey:@"image"];
		[self willChangeValueForKey:@"movie"];

		[mCurrentWord release];
		mCurrentWord = nil;
		if (!mFinishing) {
			ProVocWord *newWord = [self chooseRandomWord];
			mCurrentWord = [newWord retain];
			if (mMode == 0 || mMode == 2)
				[mWordsArray removeObject:mCurrentWord];
		}
		
		mHidingQuestionText = NO;
		mShowingQuestionMedia = YES;
		if (([self image] || [self movie]) && mMediaHideQuestion == 3)
			mShowingQuestionMedia = NO;
		else
			[self displayQuestionMedia];
		mMaskMedia = YES;
                
		[self didChangeValueForKey:@"question"];
		[self didChangeValueForKey:@"comment"];
		[self didChangeValueForKey:@"flagged"];
		[self didChangeValueForKey:@"hideQuestion"];
		[self didChangeValueForKey:@"hideComment"];
		[self didChangeValueForKey:@"font"];
		[self didChangeValueForKey:@"audio"];
		[self didChangeValueForKey:@"image"];
		[self didChangeValueForKey:@"movie"];

		[self updateWindowBackgroundColor];
        [mAnswerTextField setStringValue:@""];
		[[mAnswerTextField window] makeFirstResponder:mAnswerTextField];

        mWrongRetry = 0;
		if (!mFinishing)
	        mTestWordCurrent++;
        
		[self willChangeValueForKey:@"progress"];
		[self didChangeValueForKey:@"progress"];
		
		[self updateBackground:kBackgroundQuestion | kBackgroundAnswer | kBackgroundNewQuestion];
        
		[[self testPanel] displayIfNeeded];
		[self willChangeValueForKey:@"image"];
		[self willChangeValueForKey:@"movie"];
		mMaskMedia = NO;
		[self didChangeValueForKey:@"image"];
		[self didChangeValueForKey:@"movie"];
		[self adjustViews];

        return !mFinishing;
    } else
        return NO;
}

-(NSPanel *)testPanel
{
	return mTestPanel;
}

-(void)testEnded
{
	mFinishing = NO;
	[mTimer pause];
	[self stopMedia];
	[self savePanelLayout];
    [[self testPanel] orderOut:self];
    [NSApp endSheet:[self testPanel] returnCode:OK];
}

-(NSString *)testPanelFrameKey
{
	return @"TestPanelFrame";
}

-(NSWindow *)modalWindow
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey:PVDimTestBackground])
		return nil;
	else
		return [mProVocDocument window];
}

-(void)testPanelEnded:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
	switch (returnCode) {
		case OK:
			[self updateBackground:kBackgroundResults];
	        [self openResultPanel];
			break;
		case CANCEL:
	        [self terminateTest:YES];
			break;
		case PAUSE:
			[self terminateTest:NO];
			break;
	}
}

-(void)restorePanelLayout
{
	float deltaHeight = 0;
	int i;
	for (i = 0; i < 2; i++) {
		NSView *subview = [[mSplitView subviews] objectAtIndex:i];
		float desiredHeight = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"Split Subview %i", i]];
		if (desiredHeight > 0)
			deltaHeight += desiredHeight - [subview frame].size.height;
	}
	
	NSPanel *panel = [self testPanel];
	NSRect frame = [panel frame];
	frame.size.height += deltaHeight;
	[panel setFrame:frame display:YES];

	for (i = 0; i < 2; i++) {
		NSView *subview = [[mSplitView subviews] objectAtIndex:i];
		float desiredHeight = [[NSUserDefaults standardUserDefaults] floatForKey:[NSString stringWithFormat:@"Split Subview %i", i]];
		if (desiredHeight > 0)
			[subview setFrameSize:NSMakeSize([subview frame].size.width, desiredHeight)];
	}
	[mSplitView adjustSubviews];
}

-(void)savePanelLayout
{
	int i;
	for (i = 0; i < 2; i++) {
		NSView *subview = [[mSplitView subviews] objectAtIndex:i];
		[[NSUserDefaults standardUserDefaults] setFloat:[subview bounds].size.height forKey:[NSString stringWithFormat:@"Split Subview %i", i]];
	}
}

-(void)openTestPanel
{
	[self restorePanelLayout];
//	[[self testPanel] setFrameFromString:[[NSUserDefaults standardUserDefaults] objectForKey:[self testPanelFrameKey]]];
	if ([self modalWindow])
	    [NSApp beginSheet:[self testPanel] modalForWindow:[self modalWindow] modalDelegate:self
                    didEndSelector:@selector(testPanelEnded:returnCode:contextInfo:) contextInfo:NULL];
	else {
		NSWindow *testPanel = [self testPanel];
		[testPanel setLevel:NSFloatingWindowLevel + 2];
		int returnCode = [NSApp runModalForWindow:testPanel];
		[self testPanelEnded:[self testPanel] returnCode:returnCode contextInfo:nil];
	}
	[self savePanelLayout];
}

-(void)closePanelWithCode:(int)inCode
{
	[self stopMedia];
	[self savePanelLayout];
	[self hideNote];
    [[self testPanel] orderOut:self];
    [NSApp endSheet:[self testPanel] returnCode:inCode];
}

-(void)finishTest
{
	if (mMode == 0) {
		[mUntestedWords release];
		mUntestedWords = [mWordsArray mutableCopy];
		if ([self displayCorrectAnswer])	
			[mWrongWordsArray addObject:mCurrentWord];
		else if (!mShowingFullAnswer && !mShowingLateComment)
			[mUntestedWords addObject:mCurrentWord];
	} else {
		if ([self displayCorrectAnswer]) {
			int repetition;
			[self indexForRepetition:&repetition ofWord:mCurrentWord];
			[self historySetRepetition:repetition ofWord:mCurrentWord];
		}
	}
	[self hideNote];
	[self testEnded];
}

-(IBAction)cancelTestPanel:(id)inSender
{
	if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) == 0)
		[self finishTest];
	else if (([[NSApp currentEvent] type] != NSKeyDown || ![self hideNote]) && [inSender tag] >= 0)
		[self closePanelWithCode:CANCEL];
}

- (IBAction)pauseTestPanel:(id)sender
{
	if (mCurrentWord && ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0)
		[mProVocDocument revealWordsInPages:[NSArray arrayWithObject:[mCurrentWord word]]];
	[self closePanelWithCode:PAUSE];
}

-(NSString *)genericAnswerString:(NSString *)inAnswer
{
	static NSMutableString *answer = nil;
	if (!answer)
		answer = [[NSMutableString alloc] initWithCapacity:0];
	[answer setString:inAnswer];
	
	[answer replaceOccurrencesOfString:[NSString stringWithFormat:@"%C", 0x00A0] withString:@" " options:0 range:NSMakeRange(0, [answer length])];
	[answer replaceOccurrencesOfString:[NSString stringWithFormat:@"%C", 0x2026] withString:@"..." options:0 range:NSMakeRange(0, [answer length])];
	while ([answer replaceOccurrencesOfString:@"  " withString:@" " options:0 range:NSMakeRange(0, [answer length])])
		;
	[answer setString:[answer stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
	return [[answer copy] autorelease];
}

-(NSString *)genericAnswerString:(NSString *)inString pass:(int)inPass
{
	NSMutableString *string = /*[inString isKindOfClass:[NSMutableString class]] ? inString : */[[inString mutableCopy] autorelease];
	switch (inPass) {
		case 0:
			if (!mAnswersAccentSensitive[mDirection])
				[string removeAccents];
			if (!mAnswersCaseSensitive[mDirection])
				[string setString:[string lowercaseString]];
			if (!mAnswersPunctuationSensitive[mDirection])
				[string deleteCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
			[string deleteCharactersInSet:[NSCharacterSet symbolCharacterSet]];
			if (!mAnswersSpaceSensitive[mDirection])
				[string deleteCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			break;
		case 1: // Comments
			[string deleteParenthesis];
			[string deleteWords:mDeterminents[mDirection]];
			if ([[NSUserDefaults standardUserDefaults] boolForKey:PVPrefsUseCommentsSeparator]) {
				NSRange range = [string rangeOfString:[[NSUserDefaults standardUserDefaults] stringForKey:PVPrefCommentsSeparator]];
				if (range.location != NSNotFound)
					return [string substringToIndex:range.location];
			}
			break;
	}
	return string;
}

-(id)fullGenericAnswerString:(NSString *)inAnswer
{
	NSMutableArray *array = nil;
	NSString *string = [self genericAnswerString:inAnswer];
	int pass;
	for (pass = 0; pass <= 1; pass++) {
		NSString *passed = [self genericAnswerString:string pass:pass];
		if (![passed isEqualToString:string]) {
			if (!array)
				array = [NSMutableArray arrayWithObject:string];
			[array addObject:[self fullGenericAnswerString:passed]];
		}
	}
	return array ? (id)array : (id)string;
}

-(BOOL)isAnswerString:(NSString *)inAnswer equalToString:(NSString *)inString
{
	NSString *answer = [self genericAnswerString:inAnswer];
	NSString *word = [self genericAnswerString:inString];
    if ([answer isEqualToString:word])
		return YES;
	
	NSString *string;
	int pass;
	for (pass = 0; pass <= 1; pass++) {
		string = [self genericAnswerString:answer pass:pass];
		if (![string isEqualToString:answer] && [self isAnswerString:string equalToString:word])
			return YES;
		string = [self genericAnswerString:word pass:pass];
		if (![string isEqualToString:word] && [self isAnswerString:answer equalToString:string])
			return YES;
	}
	return NO;
}

-(BOOL)isGenericString:(id)inAnswer equalToString:(NSString *)inString
{
	if ([inAnswer isKindOfClass:[NSArray class]]) {
		NSEnumerator *enumerator = [inAnswer objectEnumerator];
		NSString *answer;
		while (answer = [enumerator nextObject])
			if ([self isGenericString:answer equalToString:inString])
				return YES;
		return NO;
	}
	
	NSString *word = [self genericAnswerString:inString];
    if ([inAnswer isEqualToString:word])
		return YES;
	
	NSString *string;
	int pass;
	for (pass = 0; pass <= 1; pass++) {
		string = [self genericAnswerString:word pass:pass];
		if (![string isEqualToString:word] && [self isGenericString:inAnswer equalToString:string])
			return YES;
	}
	return NO;
}

-(BOOL)isGenericString:(id)inString equalToWord:(NSString *)inWord
{
	NSEnumerator *enumerator = [[inWord synonyms] objectEnumerator];
	NSString *synonym;
	while (synonym = [enumerator nextObject])
		if ([self isGenericString:inString equalToString:synonym])
			return YES;
	return NO;
}

-(BOOL)isAnswer:(NSString*)answer equalToWord:(NSString*)word
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:PVPrefsUseSynonymSeparator]) {
		NSArray *answerSynonyms = [answer synonyms];
		BOOL allRight = [answerSynonyms count] > 0;
		NSEnumerator *answerSynonymEnumerator = [answerSynonyms objectEnumerator];
		NSString *answerSynonym;
		while (answerSynonym = [answerSynonymEnumerator nextObject]) {
			BOOL right = NO;
			NSArray *synonyms = [word synonyms];
			NSEnumerator *enumerator = [synonyms objectEnumerator];
			NSString *synonym;
			while (synonym = [enumerator nextObject])
				if ([self isAnswerString:answerSynonym equalToString:synonym])
					right = YES;
			if (!right)
				allRight = NO;
		}
		if (allRight)
			return YES;
	}
	return [self isAnswerString:answer equalToString:word];
}

-(BOOL)isAnswerCorrect
{
	NSString *answer = [mAnswerTextField stringValue];
	if ([self isAnswer:answer equalToWord:[self answer]])
		return YES;
		
	[self setNotesForAnswer:answer];
	NSEnumerator *enumerator = [mNoteWords objectEnumerator];
	ProVocWord *word;
	while (word = [enumerator nextObject])
		if (!mDirection ? [[mCurrentWord sourceWord] isEqual:[word sourceWord]] : [[mCurrentWord targetWord] isEqual:[word targetWord]]) {
			[mEquivalentAnswer release];
			mEquivalentAnswer = [answer retain];
			return YES;
		}
			
	return NO;
}

-(BOOL)canGiveAnswer
{
	return mShowingQuestionMedia && !mHidingQuestionText && !mShowingLateComment && !mShowingFullAnswer && !mShowingCorrectAnswer;
}

-(NSString *)verifyTitle
{
	NSString *title;
	if (mHidingQuestionText || !mShowingQuestionMedia)
		title = NSLocalizedString(@"Show Question Button Title", @"");
	else if ([self canGiveAnswer])
		title = NSLocalizedString(@"Verify Button Title", @"");
	else
		title = NSLocalizedString(@"Confirm Button Title", @"");
	return title;
}

-(void)hideAnswer
{
	[self willChangeValueForKey:@"hideComment"];
	mShowingLateComment = NO;
	mShowingFullAnswer = NO;
	[self didChangeValueForKey:@"hideComment"];
	[self updateWindowBackgroundColor];
}

-(int)currentDirection
{
	if (mRequestedDirection == 3)
		return [(ProVocDirectedWord *)mCurrentWord direction];
	else
		return mDirection;
}

-(BOOL)displayComment
{
	if ((mLateComments == 1 || mLateComments == 3 && [self currentDirection] == 1 || mLateComments == 4 && [self currentDirection] == 0) && [[mCurrentWord comment] length] > 0 ||
		(mDisplayLabels == 1 || mDisplayLabels == 3 && [self currentDirection] == 1 || mDisplayLabels == 4 && [self currentDirection] == 0) && [[mCurrentWord comment] length] > 0) {
		[self willChangeValueForKey:@"hideComment"];
		mShowingLateComment = YES;
		[self didChangeValueForKey:@"hideComment"];
		[self updateWindowBackgroundColor];
		return YES;
	} else
		return NO;
}

-(BOOL)isAnswerFullyCorrect
{
	return [[self genericAnswerString:[mAnswerTextField stringValue]] isEqualToString:[self genericAnswerString:[self answer]]];
}

-(BOOL)shouldPlayAudioForFullAnswer
{
	return YES;
}

-(BOOL)displayFullAnswer
{
    if ([self isAnswerFullyCorrect] && !([self canPlayAnswerAudio] && mAutoPlayMedia && [self shouldPlayAudioForFullAnswer]))
		return NO;
	else {
		[self willChangeValueForKey:@"canGiveAnswer"];
		mShowingFullAnswer = YES;
		if ([self canPlayAnswerAudio] && mAutoPlayMedia)
			[self playAnswerAudio:nil];
		[self didChangeValueForKey:@"canGiveAnswer"];
		[mAnswerTextField setStringValue:[self correctAnswer]];
		return YES;
	}
}

-(BOOL)hideQuestion
{
	return mHidingQuestionText;
}

-(BOOL)displayAnswer
{
	BOOL display = NO;
	if ([self displayComment])
		display = YES;
	if ([self displayFullAnswer])
		display = YES;
	if (display)
		[self updateBackground:kBackgroundAnswer];
	return display;
}

-(BOOL)displayCorrectAnswer
{
	return mShowingCorrectAnswer;
}

-(void)setDisplayCorrectAnswer:(BOOL)inDisplay
{
	if (mShowingCorrectAnswer != inDisplay) {
		[self willChangeValueForKey:@"displayCorrectAnswer"];
		mShowingCorrectAnswer = inDisplay;
		if (mShowingCorrectAnswer && [self canPlayAnswerAudio] && mAutoPlayMedia)
			[self playAnswerAudio:nil];
		[self didChangeValueForKey:@"displayCorrectAnswer"];
		[self updateBackground:kBackgroundAnswer];
	}
}

-(NSMutableDictionary *)peekInfoForLearnedWord:(id)inWord
{
	int index = [mLearnedWords indexOfObject:inWord];
	if (index != NSNotFound)
		return [mLearnedWordsInfo objectAtIndex:index];
	else
		return nil;
}

-(NSMutableDictionary *)infoForLearnedWord:(id)inWord
{
	if (!mLearnedWords) {
		int n = [mWordsArray count];
		mLearnedWords = [[NSMutableArray alloc] initWithCapacity:n];
		mLearnedWordsInfo = [[NSMutableArray alloc] initWithCapacity:n];
	}
	int index = [mLearnedWords indexOfObject:inWord];
	NSMutableDictionary *info;
	if (index != NSNotFound)
		info = [mLearnedWordsInfo objectAtIndex:index];
	else {
		info = [NSMutableDictionary dictionary];
		[mLearnedWords addObject:inWord];
		[mLearnedWordsInfo addObject:info];
	}
	return info;
}

-(int)repetitionOffsetOfLearnedWord:(id)inWord
{
	return [[[self peekInfoForLearnedWord:inWord] objectForKey:@"RepetitionOffset"] intValue];
}

-(int)peekRepetitionOfWord:(id)inWord
{
	NSEnumerator *enumerator = [mRepetitions objectEnumerator];
	NSMutableSet *set;
	int index = 0;
	while (set = [enumerator nextObject]) {
		index++;
		if ([set containsObject:inWord])
			return index;
	}
	return 0;
}

-(int)indexForRepetitionCount:(int)inCount
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:PVLearnedDistractInterval] * inCount;
}

-(int)indexForRepetition:(int *)outRepetition ofWord:(id)inWord
{
	int repetition = 0;
	NSEnumerator *enumerator = [mRepetitions objectEnumerator];
	NSMutableSet *set;
	int index = 0;
	while (set = [enumerator nextObject]) {
		index++;
		if ([set containsObject:inWord]) {
			[set removeObject:inWord];
			repetition = index;
			break;
		}
	}
	if (!mRepetitions)
		mRepetitions = [[NSMutableArray alloc] initWithCapacity:0];
	if (repetition < [mRepetitions count])
		set = [mRepetitions objectAtIndex:repetition];
	else {
		set = [NSMutableSet set];
		[mRepetitions addObject:set];
	}
	[set addObject:inWord];
	
	if (outRepetition)
		*outRepetition = repetition + 1;
	return [self indexForRepetitionCount:repetition + 1 - [self repetitionOffsetOfLearnedWord:inWord]];
}

-(void)updateBackground:(int)inWhat
{
	ProVocBackground *background = [ProVocBackground sharedBackground];
	if (inWhat & kBackgroundResults) {
		[background setValue:nil forInputKey:@"Question"];
		[background setValue:nil forInputKey:@"Answer"];
		[background setValue:[NSNumber numberWithBool:YES] forInputKey:@"Results"];
	} else {
		[background setValue:[NSNumber numberWithBool:NO] forInputKey:@"Results"];
		if (inWhat & kBackgroundQuestion)
			[background setValue:[self question] forInputKey:@"Question"];
		if (inWhat & kBackgroundAnswer)
			[background setValue:mShowingFullAnswer || mShowingCorrectAnswer || mShowingLateComment ? [self answer] : nil forInputKey:@"Answer"];
		if (inWhat & kBackgroundNewQuestion)
			[background triggerInputKey:@"NewQuestion"];
		if (inWhat & kBackgroundCorrectAnswer)
			[background triggerInputKey:@"CorrectAnswer"];
		if (inWhat & kBackgroundWrongAnswer)
			[background triggerInputKey:@"WrongAnswer"];
	}
}

-(void)wordWasAnsweredCorrectly:(ProVocWord *)inWord
{
	[inWord incrementRight];
	[mCorrectlyAnswered addObject:inWord];
	if (mMode == 2) {
		int consecutiveRepetitions = [[NSUserDefaults standardUserDefaults] integerForKey:PVLearnedConsecutiveRepetitions];
		if (consecutiveRepetitions > 1) {
			NSMutableDictionary *info = [self infoForLearnedWord:inWord];
			[info setObject:[NSNumber numberWithInt:[self peekRepetitionOfWord:inWord]] forKey:@"RepetitionOffset"];
			int consecutiveCorrectAnswers = [[info objectForKey:@"ConsecutiveCorrectAnswers"] intValue] + 1;
			[info setObject:[NSNumber numberWithInt:consecutiveCorrectAnswers] forKey:@"ConsecutiveCorrectAnswers"];
			if (consecutiveCorrectAnswers < consecutiveRepetitions && [mWordsArray count] > 0) {
				int index = MIN([self indexForRepetitionCount:1] + rand() % 5, [mWordsArray count]);
				[mWordsArray insertObject:inWord atIndex:index];
				mTestWordCurrent--;
			}
		}
	}
}

-(void)wordWasAnsweredWrongly:(ProVocWord *)inWord
{
	if (mMode == 2) {
		NSMutableDictionary *info = [self peekInfoForLearnedWord:inWord];
		[info removeObjectForKey:@"ConsecutiveCorrectAnswers"];
	}
	
	while (mWrongRetry++ < mMaxRetryCount)
		[inWord incrementWrong];
}

-(BOOL)ignoreRebound
{
	static NSTimeInterval lastTime = 0;
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
	BOOL ignore = now - lastTime < 0.2;
	lastTime = now;
	return ignore;
}

-(IBAction)verifyTestPanel:(id)sender
{
	if ([self ignoreRebound])
		return;
	
	[mEquivalentAnswer release];
	mEquivalentAnswer = nil;
	
	int repetition = [self peekRepetitionOfWord:mCurrentWord];
	ProVocWord *currentWord = [[mCurrentWord retain] autorelease];
	
	if (!mShowingQuestionMedia) {
		[self willChangeValueForKey:@"hideQuestion"];
		[self willChangeValueForKey:@"image"];
		[self willChangeValueForKey:@"movie"];
		[self displayQuestionMedia];
		[self didChangeValueForKey:@"hideQuestion"];
		[self didChangeValueForKey:@"image"];
		[self didChangeValueForKey:@"movie"];
		[[mAnswerTextField window] makeFirstResponder:mAnswerTextField];
		[self adjustViews];
		[self updateBackground:kBackgroundQuestion];
	} else if (mHidingQuestionText) {
		[self willChangeValueForKey:@"hideQuestion"];
		mHidingQuestionText = NO;
		[self didChangeValueForKey:@"hideQuestion"];
		[[mAnswerTextField window] makeFirstResponder:mAnswerTextField];
		[self updateBackground:kBackgroundQuestion];
	} else if ([self displayCorrectAnswer]) {
		BOOL accept = [sender respondsToSelector:@selector(boolValue)] && [sender boolValue];
		if (accept) {
			if (mWrongRetry > 0)
				[mCurrentWord decrementWrong];
			[self wordWasAnsweredCorrectly:mCurrentWord];
		} else {
			repetition = 1;

			if (mMode == 0)
				[mWrongWordsArray addObject:mCurrentWord];
			else if (mMode == 1)
				[self indexForRepetition:&repetition ofWord:mCurrentWord];
			else if (mMode == 2) {
				int index = MIN([self indexForRepetition:&repetition ofWord:mCurrentWord], [mWordsArray count]);
				[mWordsArray insertObject:mCurrentWord atIndex:index];
				mTestWordCurrent--;
			}
			
			[self wordWasAnsweredWrongly:mCurrentWord];
		}
		
		[self hideNote];
		
		[self setDisplayCorrectAnswer:NO];
		if (![self applyRandomWord] && !mFinishing)
			[self testEnded];
	} else if (![self canGiveAnswer]) {
		[self hideAnswer];
		NSWindow *window = [self testPanel];
		[window performSelector:@selector(makeFirstResponder:) withObject:[window initialFirstResponder] afterDelay:0.0 inModes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSModalPanelRunLoopMode, nil]];
		if (![self applyRandomWord])
			[self testEnded];
    } else if ([self isAnswerCorrect]) {
		[self updateBackground:kBackgroundCorrectAnswer];
		[self wordWasAnsweredCorrectly:mCurrentWord];
		if (![self displayAnswer] && ![self applyRandomWord])
			[self testEnded];
    } else {
		[self updateBackground:kBackgroundWrongAnswer];
		NSWindow *window = [self modalWindow];
		if (!window)
			window = [self testPanel];
        [window shake];
        
		repetition++;
		
        [mCurrentWord incrementWrong];
        if (++mWrongRetry == mMaxRetryCount)
            [self giveAnswerTestPanel:nil];
    }

	[self historySetRepetition:repetition ofWord:currentWord];
	if (mTimerDidElapse) {
		mTimerDidElapse = NO;
		[self timerDidElapse:nil];
	}
}

-(NSString *)userAnswerString
{
	return [mAnswerTextField stringValue];
}

-(NSString *)correctAnswer
{
	NSString *answer = [self answer];
	if (mEquivalentAnswer)
		answer = [NSString stringWithFormat:@"%@%@%@", mEquivalentAnswer, [[NSUserDefaults standardUserDefaults] stringForKey:PVPrefSynonymSeparator], answer];
	return answer;
}

-(BOOL)canGiveHint
{
	return YES;
}

-(NSString *)giveAnswerTitle
{
	return ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) == 0 || ![self canGiveHint] ? NSLocalizedString(@"Give Answer Button Title", @"") : NSLocalizedString(@"Give Hint Button Title", @"");
}

-(void)giveHint
{
	NSMutableArray *hints = [NSMutableArray array];
	NSArray *answerSynonyms = [[mAnswerTextField stringValue] synonyms];
	NSEnumerator *enumerator = [[[self correctAnswer] synonyms] objectEnumerator];
	NSString *solution;
	int maxHintLength = 0;
	while (solution = [enumerator nextObject]) {
		int hintLength = 0;
		NSEnumerator *answerEnumerator = [answerSynonyms objectEnumerator];
		NSString *answer;
		while (answer = [answerEnumerator nextObject])
			hintLength = MAX(hintLength, [[solution commonPrefixWithString:answer options:NSLiteralSearch | NSCaseInsensitiveSearch] length]);
		while (hintLength < [solution length] && [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[solution characterAtIndex:hintLength]])
			hintLength++;
		hintLength = MIN([solution length], hintLength + 1);
		maxHintLength = MAX(maxHintLength, hintLength);
		[hints addObject:[solution substringToIndex:hintLength]];
	}
	if (maxHintLength > 1) {
		NSEnumerator *enumerator = [hints reverseObjectEnumerator];
		NSString *hint;
		while (hint = [enumerator nextObject])
			if ([hint length] == 1)
				[hints removeObject:hint];
	}
	NSString *hint = [hints componentsJoinedByString:[[NSUserDefaults standardUserDefaults] stringForKey:PVPrefSynonymSeparator]];
	[mAnswerTextField setStringValue:hint];
	[[mAnswerTextField currentEditor] moveToEndOfDocument:nil];
}

-(IBAction)giveAnswerTestPanel:(id)sender
{
	if ([self canGiveHint] && ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0)
		[self giveHint];
	else {
		[self showNoteForAnswer:[self userAnswerString]];
		[self setDisplayCorrectAnswer:YES];
	}
}

-(IBAction)acceptAnswer:(id)sender
{
	[self verifyTestPanel:[NSNumber numberWithBool:YES]];
}

-(BOOL)hideComment
{
	return mLateComments == 2 || (mLateComments == 1 || mLateComments == 3 && [self currentDirection] == 1 || mLateComments == 4 && [self currentDirection] == 0) && !mShowingLateComment && !mShowingCorrectAnswer;
}

-(BOOL)shouldHideLabel
{
	return mDisplayLabels == 2 || (mDisplayLabels == 1 || mDisplayLabels == 3 && [self currentDirection] == 1 || mDisplayLabels == 4 && [self currentDirection] == 0) && !mShowingLateComment && !mShowingCorrectAnswer;
}

-(BOOL)hideLabel
{
	[self updateWindowBackgroundColor];
	return [self shouldHideLabel];
}

-(NSString *)questionFontFamilyName
{
	return !mDirection ? [mProVocDocument sourceFontFamilyName] : [mProVocDocument targetFontFamilyName];
}

-(float)questionFontSize
{
	return !mDirection ? [mProVocDocument sourceTestFontSize] : [mProVocDocument targetTestFontSize];
}

-(NSString *)answerFontFamilyName
{
	return mDirection ? [mProVocDocument sourceFontFamilyName] : [mProVocDocument targetFontFamilyName];
}

-(float)answerFontSize
{
	return mDirection ? [mProVocDocument sourceTestFontSize] : [mProVocDocument targetTestFontSize];
}

-(NSString *)sourceFontFamilyName
{
	return [mProVocDocument sourceFontFamilyName];
}

-(float)sourceFontSize
{
	return [mProVocDocument sourceTestFontSize];
}

-(NSString *)targetFontFamilyName
{
	return [mProVocDocument targetFontFamilyName];
}

-(float)targetFontSize
{
	return [mProVocDocument targetTestFontSize];
}

-(NSString *)commentFontFamilyName
{
	return [mProVocDocument commentFontFamilyName];
}

-(float)commentFontSize
{
	return [mProVocDocument commentTestFontSize];
}

-(NSColor *)commentTextColor
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"commentTextColor"];
}

-(NSWritingDirection)sourceWritingDirection
{
	return [mProVocDocument sourceWritingDirection];
}

-(NSWritingDirection)targetWritingDirection
{
	return [mProVocDocument targetWritingDirection];
}

-(NSWritingDirection)commentWritingDirection
{
	return [mProVocDocument commentWritingDirection];
}

-(NSWritingDirection)questionWritingDirection
{
	return !mDirection ? [mProVocDocument sourceWritingDirection] : [mProVocDocument targetWritingDirection];
}

-(NSWritingDirection)answerWritingDirection
{
	return mDirection ? [mProVocDocument sourceWritingDirection] : [mProVocDocument targetWritingDirection];
}

@end

@implementation ProVocTester (Pause)

-(void)flagsChanged:(NSEvent *)inEvent
{
	[self willChangeValueForKey:@"abortTitle"];
	[self didChangeValueForKey:@"abortTitle"];
	[self willChangeValueForKey:@"pauseTitle"];
	[self didChangeValueForKey:@"pauseTitle"];
	[self willChangeValueForKey:@"giveAnswerTitle"];
	[self didChangeValueForKey:@"giveAnswerTitle"];
}

-(NSString *)pauseTitle
{
	return ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) == 0 ? NSLocalizedString(@"Pause Button Title", @"") : NSLocalizedString(@"Edit Button Title", @"");
}

-(NSString *)abortTitle
{
	return ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0 ? NSLocalizedString(@"Abort Button Title", @"") : NSLocalizedString(@"Finish Button Title", @"");
}

@end

@implementation ProVocTester (ResultPanel)

-(BOOL)canRepeatWrongWords
{
	return [mWrongWordsArray count] > 0;
}

-(void)resultPanelEnded:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
	[mResultPanel orderOut:self];
    if (returnCode == OK) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:PVMarkWrongWords]) {
			int label = [[NSUserDefaults standardUserDefaults] integerForKey:PVLabelForWrongWords] - 1;
			NSEnumerator *enumerator = [mWrongWordsArray objectEnumerator];
			ProVocWord *word;
			while (word = [enumerator nextObject])
				if (label < 0)
					[word setMark:1];
				else
					[word setLabel:label];
		}
		if ([[NSUserDefaults standardUserDefaults] boolForKey:PVSlideShowWithWrongWords]) {
			if ([[NSUserDefaults standardUserDefaults] boolForKey:PVDimTestBackground])
				[[ProVocBackground sharedBackground] hide];
			[mTimer hide];
			[NSScreen dimScreensHidingMenuBar:YES];
			[mProVocDocument slideshowWithWords:mWrongWordsArray];
			[NSScreen dimScreensHidingMenuBar:![[NSUserDefaults standardUserDefaults] boolForKey:PVFullScreenWithMenuBar]];
			[NSScreen undimScreens];
			[NSScreen undimScreens];
			if ([[NSUserDefaults standardUserDefaults] boolForKey:PVDimTestBackground])
				[[ProVocBackground sharedBackground] display];
		}

		mWholeRepetition++;
		[mWordsArray setArray:mWrongWordsArray];
		[mTestedWords release];
		mTestedWords = [mWordsArray copy];
		[self shuffleWords];
		[self restartTest];
		[mTimer start];
		[self openTestPanel];
    } else
        [self terminateTest:YES];
}

-(void)showResultPanel
{
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:PVMarkWrongWords];
	[mLabelPopUp2 selectItemAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:PVLabelForWrongWords]];
	if ([self modalWindow])
		[NSApp beginSheet:mResultPanel modalForWindow:[self modalWindow] modalDelegate:self
						didEndSelector:@selector(resultPanelEnded:returnCode:contextInfo:) contextInfo:NULL];
	else {
		int returnCode = [NSApp runModalForWindow:mResultPanel];
		[self resultPanelEnded:mResultPanel returnCode:returnCode contextInfo:nil];
	}
}

-(void)openResultPanel
{
	[mResultView removeResults];
	if (mMode == 0) {
		[mResultView addResult:NSLocalizedString(@"Result Correct Title", @"") value:mTestWordMax - [mWrongWordsArray count] - [mUntestedWords count] color:[NSColor greenColor]];
		[mResultView addResult:NSLocalizedString(@"Result Wrong Title", @"") value:[mWrongWordsArray count] color:[NSColor redColor]];
		if (mUntestedWords) {
			[mResultView addResult:NSLocalizedString(@"Result Ignored Title", @"") value:[mUntestedWords count] color:[NSColor colorWithCalibratedWhite:0.85 alpha:0.5]];
			[mWrongWordsArray addObjectsFromArray:mUntestedWords];
			[mUntestedWords release];
			mUntestedWords = nil;
		}
	} else {
		int wrongs[MAX_HISTORY_REPETITION];
		int i;
		for (i = 0; i < MAX_HISTORY_REPETITION; i++)
			wrongs[i] = 0;
		NSEnumerator *enumerator = [mRepetitions objectEnumerator];
		id repetition;
		i = 0;
		int totalWrong = 0;
		while (repetition = [enumerator nextObject]) {
			int n = [repetition count];
			totalWrong += n;
			wrongs[MIN(i++, MAX_HISTORY_REPETITION - 1)] += n;
			[mWrongWordsArray addObjectsFromArray:[repetition allObjects]];
		}
		[mRepetitions release];
		mRepetitions = nil;
		NSMutableArray *correctlyAnswered = [[[mCorrectlyAnswered allObjects] mutableCopy] autorelease];
		[correctlyAnswered removeObjectsInArray:mWrongWordsArray];
		NSMutableArray *allWrongWords = [[mTestedWords mutableCopy] autorelease];
		[allWrongWords removeObjectsInArray:correctlyAnswered];
		[mWrongWordsArray setArray:allWrongWords];
		
		int correct = [correctlyAnswered count];
		int ignored = mTestWordMax - totalWrong - [correctlyAnswered count];
		
		[mResultView addResult:NSLocalizedString(@"Result Correct Title", @"") value:correct color:[ProVocHistory colorForRepetition:0]];
		[mResultView addResult:NSLocalizedString(@"Result Wrong Once Title", @"") value:wrongs[0] color:[ProVocHistory colorForRepetition:1]];
		[mResultView addResult:NSLocalizedString(@"Result Wrong Twice Title", @"") value:wrongs[1] color:[ProVocHistory colorForRepetition:2]];
		[mResultView addResult:NSLocalizedString(@"Result Wrong 3+ Title", @"") value:wrongs[2] color:[ProVocHistory colorForRepetition:3]];
		if (ignored > 0)
			[mResultView addResult:NSLocalizedString(@"Result Ignored Title", @"") value:ignored color:[NSColor colorWithCalibratedWhite:0.85 alpha:0.5]];
	}

	[self willChangeValueForKey:@"canRepeatWrongWords"];
	[self didChangeValueForKey:@"canRepeatWrongWords"];
	[mRetryButton setHidden:[mWrongWordsArray count] == 0];
    if (![self canRepeatWrongWords]) {
        [mRetryButton setKeyEquivalent:@""];
        [mTerminateButton setKeyEquivalent:@"\r"];
    }
    
	if (mMode != 0)
		mFreezeHistory = YES;
	[self showResultPanel];
}

-(IBAction)terminateResultPanel:(id)sender
{
    [NSApp endSheet:mResultPanel returnCode:CANCEL];
}

-(IBAction)retryResultPanel:(id)sender
{
	[NSApp endSheet:mResultPanel returnCode:OK];
}

@end

@implementation ProVocTester (Note)

-(BOOL)multipleNote
{
	return [mNoteWords count] > 1;
}

-(id)maxNoteIndex
{
	return [NSNumber numberWithUnsignedInt:MAX(1, [mNoteWords count]) - 1];
}

-(NSArray *)noteWords
{
	return mNoteWords;
}

-(NSArray *)allWordsForNotes
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey:PVBackTranslationWithAllWords])
		return [mProVocDocument allWords];
	else
		return mAllWords;
}

-(void)setNotesForAnswer:(NSString *)inString
{
	if ([mSourceOfNoteWords isEqual:inString])
		return;
	[mSourceOfNoteWords release];
	mSourceOfNoteWords = [inString retain];
	
	if (!mNoteWords)
		mNoteWords = [[NSMutableArray alloc] initWithCapacity:0];
	else
		[mNoteWords removeAllObjects];

	id string = [self fullGenericAnswerString:inString];
	ProVocWord *currentWord = [mCurrentWord word];
	NSEnumerator *enumerator = [[self allWordsForNotes] objectEnumerator];
	ProVocWord *word;
	while (word = [[enumerator nextObject] word])
		if (![currentWord isEqual:word]) {
			NSString *answer = mDirection ? [word sourceWord] : [word targetWord];
			if ([self isGenericString:string equalToWord:answer])
				[mNoteWords addObject:word];
		}
}

-(void)showNoteForAnswer:(NSString *)inString
{
	if (!mShowBacktranslation || [inString length] == 0 || [[self genericAnswerString:inString] length] == 0)
		return;
	
	[self willChangeValueForKey:@"noteWords"];
	[self setNotesForAnswer:inString];
	[self didChangeValueForKey:@"noteWords"];

	if ([mNoteWords count] > 0) {
		[mNotePanel setWorksWhenModal:YES];
		[mNotePanel setLevel:NSModalPanelWindowLevel];
		[mNotePanel performSelector:@selector(orderFront:) withObject:nil afterDelay:0.0 inModes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSModalPanelRunLoopMode, nil]]; 
	}
	
	[NSApp discardEventsMatchingMask:NSKeyDownMask beforeEvent:nil];
}

-(BOOL)hideNote
{
	BOOL wasVisible = [mNotePanel isVisible];
	[mNotePanel orderOut:nil];
	return wasVisible;
}

@end

@implementation ProVocDirectedWord

-(id)initWithWord:(ProVocWord *)inWord direction:(int)inDirection
{
	if (self = [super init]) {
		mWord = [inWord retain];
		mDirection = inDirection;
	}
	return self;
}

-(void)dealloc
{
	[mWord release];
	[super dealloc];
}

-(id)copy
{
	ProVocWord *wordCopy = [mWord copy];
	id copy = [[[self class] alloc] initWithWord:wordCopy direction:[self direction]];
	[wordCopy release];
	return copy;
}

-(ProVocWord *)word
{
	return mWord;
}

-(int)direction
{
	return mDirection;
}

-(void)forwardInvocation:(NSInvocation *)inInvocation
{
	[inInvocation invokeWithTarget:mWord];
}

-(NSMethodSignature *)methodSignatureForSelector:(SEL)inSelector
{
	if ([self respondsToSelector:inSelector])
		return [super methodSignatureForSelector:inSelector];
	else
		return [mWord methodSignatureForSelector:inSelector];
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"<%@ 0x%x (word=%@, dir=%i)>", NSStringFromClass([self class]), self, mWord, mDirection];
}

@end

@implementation ProVocSynonymWord

-(id)initWithWord:(ProVocWord *)inWord
{
	if (self = [super init]) {
		mWord = [inWord retain];
		[self setSourceWord:[mWord sourceWord]];
		[self setTargetWord:[mWord targetWord]];
	}
	return self;
}

-(void)dealloc
{
	[mWord release];
	[mSourceWord release];
	[mTargetWord release];
	[super dealloc];
}

-(id)copy
{
	return [[[self class] alloc] initWithWord:mWord];
}

-(ProVocWord *)word
{
	return mWord;
}

-(BOOL)respondsToSelector:(SEL)inSelector
{
	if (inSelector == @selector(direction))
		return [mWord respondsToSelector:inSelector];
	else
		return [super respondsToSelector:inSelector];
}

-(int)direction
{
	return [(ProVocDirectedWord *)mWord direction];
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"<%@ 0x%x (word=%@)>", NSStringFromClass([self class]), self, mWord];
}

-(void)setSourceWord:(NSString *)inSource
{
	[mSourceWord autorelease];
	mSourceWord = [inSource retain];
}

-(void)setTargetWord:(NSString *)inTarget
{
	[mTargetWord autorelease];
	mTargetWord = [inTarget retain];
}

-(NSString *)sourceWord
{
	return mSourceWord;
}

-(NSString *)targetWord
{
	return mTargetWord;
}

-(void)forwardInvocation:(NSInvocation *)inInvocation
{
	[inInvocation invokeWithTarget:mWord];
}

-(NSMethodSignature *)methodSignatureForSelector:(SEL)inSelector
{
	if ([self respondsToSelector:inSelector])
		return [super methodSignatureForSelector:inSelector];
	else
		return [mWord methodSignatureForSelector:inSelector];
}

@end

@interface NSCharacterSet (ProVocTester)

+(NSString *)stringWithOpenBrackets;
+(NSCharacterSet *)openBracketCharacterSet;

@end

@interface NSScanner (ProVocTester)

-(BOOL)scanBrackettedComponent:(NSString **)outString;
-(BOOL)scanUnbrackettedComponent:(NSString **)outString separatedBy:(NSString *)inSeparator;

@end

@implementation NSString (ProVocTester)

-(NSArray *)synonyms
{
	if (![[NSUserDefaults standardUserDefaults] boolForKey:PVPrefsUseSynonymSeparator])
		return [NSArray arrayWithObject:self];
		
	NSString *separator = [[NSUserDefaults standardUserDefaults] stringForKey:PVPrefSynonymSeparator];
	if ([self rangeOfString:separator].location == NSNotFound)
		return [NSArray arrayWithObject:self];
	else if ([self rangeOfCharacterFromSet:[NSCharacterSet openBracketCharacterSet]].location == NSNotFound)
		return [self componentsSeparatedByString:separator];
	else {
		NSMutableArray *synonyms = [NSMutableArray array];
		NSScanner *scanner = [NSScanner scannerWithString:self];
		while (![scanner isAtEnd]) {
			NSString *synonym;
			if ([scanner scanUnbrackettedComponent:&synonym separatedBy:separator])
				[synonyms addObject:synonym];
		}
		return synonyms;
	}
}

@end

@implementation NSCharacterSet (ProVocTester)

+(NSString *)stringWithOpenBrackets
{
	return @"({[";
}

+(NSCharacterSet *)openBracketCharacterSet
{
	static NSCharacterSet *set = nil;
	if (!set)
		set = [[NSCharacterSet characterSetWithCharactersInString:[self stringWithOpenBrackets]] retain];
	return set;
}

@end

@implementation NSScanner (ProVocTester)

-(BOOL)scanBrackettedComponent:(NSString **)outString
{
	if ([self isAtEnd])
		return NO;
	NSMutableString *buffer = [NSMutableString string];
	NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:[[NSCharacterSet stringWithOpenBrackets] stringByAppendingString:@")}]"]];
	NSString *string;
	if ([self scanUpToCharactersFromSet:set intoString:&string])
		[buffer appendString:string];
	NSString *bracket;
	if ([self scanString:@"(" intoString:&bracket] || [self scanString:@"{" intoString:&bracket] ||[self scanString:@"[" intoString:&bracket]) {
		[buffer appendString:bracket];
		if ([self scanBrackettedComponent:&string])
			[buffer appendString:string];
		static NSDictionary *unbrackets = nil;
		if (!unbrackets)
			unbrackets = [[NSDictionary alloc] initWithObjectsAndKeys:@")", @"(", @"}", @"{", @"]", @"[", nil];
		if ([self scanString:[unbrackets objectForKey:bracket] intoString:&string])
			[buffer appendString:string];
	}
	if (outString)
		*outString = buffer;
	return YES;
}

-(BOOL)scanUnbrackettedComponent:(NSString **)outString separatedBy:(NSString *)inSeparator
{
	if ([self isAtEnd])
		return NO;
		
	NSMutableString *buffer = [NSMutableString string];
	NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:[[NSCharacterSet stringWithOpenBrackets] stringByAppendingString:inSeparator]];
	NSString *string;
	while (![self isAtEnd]) {
		if ([self scanUpToCharactersFromSet:set intoString:&string])
			[buffer appendString:string];
		if ([self scanString:inSeparator intoString:nil])
			break;
		else if ([self scanBrackettedComponent:&string])
			[buffer appendString:string];
	}
	if (outString)
		*outString = buffer;
	return YES;
}

@end


@implementation ProVocTestPanel

-(void)setLabel:(id)inSender
{
	[[self delegate] setLabel:inSender];
}

-(void)flagsChanged:(NSEvent *)inEvent
{
	[mTester flagsChanged:inEvent];
}

@end

@implementation ProVocTester (History)

-(void)historyStart
{
	[mHistoryStart release];
	mHistoryStart = [[NSDate date] retain];
	[mHistory release];
	mHistory = [[NSMutableArray alloc] initWithCapacity:MAX_HISTORY_REPETITION + 1];
	int i;
	for (i = 0; i <= MAX_HISTORY_REPETITION; i++)
		[mHistory addObject:[NSMutableSet set]];
}

-(void)historySetRepetition:(int)inRepetition ofWord:(ProVocWord *)inWord
{
	if (mFreezeHistory)
		return;
	int repetition = inRepetition;
	if (mMode == 0)
		repetition += mWholeRepetition;
	repetition = MIN(MAX_HISTORY_REPETITION, repetition);
	int i;
	for (i = 0; i <= MAX_HISTORY_REPETITION; i++) {
		NSMutableSet *set = [mHistory objectAtIndex:i];
		if (i == repetition)
			[set addObject:inWord];
		else
			[set removeObject:inWord];
	}
}

-(void)historyCommit
{
	ProVocHistory *history = [[ProVocHistory alloc] init];
	[history setDate:mHistoryStart];
	[history setMode:mMode];
	int i;
	for (i = 0; i <= MAX_HISTORY_REPETITION; i++) {
		int count = [[mHistory objectAtIndex:i] count];
		[history setNumber:count ofRepetition:i];
	}
	if ([history total] > 0) {
		if (mReplaceLastHistory) {
			[mProVocDocument removeLastHistory];
			mReplaceLastHistory = NO;
		}
		[mProVocDocument addHistory:history];
	}
	[history release];
}

@end

@implementation ProVocTester (Image)

-(ProVocWord *)wordForImage
{
	return [mCurrentWord word];
}

-(NSImage *)image
{
	if (mImageMCQ || !mShowingQuestionMedia || mMediaHideQuestion == 4 || mMaskMedia)
		return nil;
	return [mProVocDocument imageOfWord:[self wordForImage]];
}

@end

@implementation ProVocTester (Movie)

-(ProVocWord *)wordForMovie
{
	return [mCurrentWord word];
}

-(id)movie
{
	if (mImageMCQ || !mShowingQuestionMedia || mMediaHideQuestion == 4 || mMaskMedia)
		return nil;
	return [mProVocDocument movieOfWord:[self wordForMovie]];
}

-(id)nonNilMovie
{
	id movie = [self movie];
	if (movie) {
		[mLastMovie release];
		mLastMovie = [movie retain];
	}
	return mLastMovie;
}

@end

@implementation ProVocTester (Audio)

-(NSString *)questionAudioKey
{
	return ![self currentDirection] ? @"Source" : @"Target";
}

-(NSString *)answerAudioKey
{
	return [self currentDirection] ? @"Source" : @"Target";
}

-(ProVocWord *)wordForAudio
{
	return [mCurrentWord word];
}

-(BOOL)canSpeakLanguage:(NSString *)inLanguage
{
	return [inLanguage rangeOfString:@"English" options:NSCaseInsensitiveSearch].location != NSNotFound;
}

-(BOOL)canPlayQuestionWordAudio
{
	return [[self wordForAudio] canPlayAudio:[self questionAudioKey]];
}

-(BOOL)canSpeakQuestion
{
	if (!mUseSpeechSynthesizer)
		return NO;
	return ![self currentDirection] && [self canSpeakLanguage:[mProVocDocument sourceLanguage]] && [[mCurrentWord sourceWord] length] > 0 ||
			[self currentDirection] && [self canSpeakLanguage:[mProVocDocument targetLanguage]] && [[mCurrentWord targetWord] length] > 0;
}

-(BOOL)canPlayQuestionAudio
{
	return [self canPlayQuestionWordAudio] || [self canSpeakQuestion];
}

-(BOOL)canPlayAnswerWordAudio
{
	return [[self wordForAudio] canPlayAudio:[self answerAudioKey]];
}

-(BOOL)canSpeakAnswer
{
	if (!mUseSpeechSynthesizer)
		return NO;
	return [self currentDirection] && [self canSpeakLanguage:[mProVocDocument sourceLanguage]] && [[mCurrentWord sourceWord] length] > 0 ||
			![self currentDirection] && [self canSpeakLanguage:[mProVocDocument targetLanguage]] && [[mCurrentWord targetWord] length] > 0;
}

-(BOOL)canPlayAnswerAudio
{
	return [self canPlayAnswerWordAudio] || [self canSpeakAnswer];
}

-(NSImage *)questionAudioImage
{
	BOOL playing = mSpeechSynthesizerState == 1 || [mProVocDocument isPlayingAudio:[self questionAudioKey] ofWord:[self wordForAudio]];
	return [NSImage imageNamed:playing ? @"SpeakerOn" : @"SpeakerOff"];
}

-(NSImage *)answerAudioImage
{
	BOOL playing = mSpeechSynthesizerState == 2 || [mProVocDocument isPlayingAudio:[self answerAudioKey] ofWord:[self wordForAudio]];
	return [NSImage imageNamed:playing ? @"SpeakerOn" : @"SpeakerOff"];
}

-(void)stopSpeaking
{
	[mSpeechSynthesizer stopSpeaking];
}

-(void)speak:(NSString *)inText state:(int)inState
{
	[self willChangeValueForKey:@"questionAudioImage"];
	[self willChangeValueForKey:@"answerAudioImage"];
	[self stopSpeaking];
	if (!mSpeechSynthesizer) {
		mSpeechSynthesizer = [[NSSpeechSynthesizer alloc] initWithVoice:mVoiceIdentifier];
		if (!mSpeechSynthesizer)
			mSpeechSynthesizer = [[NSSpeechSynthesizer alloc] initWithVoice:nil];
		[mSpeechSynthesizer setDelegate:self];
	}
	[mSpeechSynthesizer stopSpeaking]; // ++++ v4.2.2 ++++
	[mSpeechSynthesizer startSpeakingString:inText];
	mSpeechSynthesizerState = inState;
	[self didChangeValueForKey:@"questionAudioImage"];
	[self didChangeValueForKey:@"answerAudioImage"];
}

-(void)speechSynthesizer:(NSSpeechSynthesizer *)inSynthesizer didFinishSpeaking:(BOOL)inFinishedSpeaking
{
	[self willChangeValueForKey:@"questionAudioImage"];
	[self willChangeValueForKey:@"answerAudioImage"];
	mSpeechSynthesizerState = 0;
	[self didChangeValueForKey:@"questionAudioImage"];
	[self didChangeValueForKey:@"answerAudioImage"];
}

-(IBAction)playQuestionAudio:(id)inSender
{
	[mMCQView stopMedia];
	if ([self canPlayQuestionWordAudio])
		[mProVocDocument playAudio:[self questionAudioKey] ofWord:[self wordForAudio]];
	else if ([self canSpeakQuestion])
		[self speak:![self currentDirection] ? [mCurrentWord sourceWord] : [mCurrentWord targetWord] state:1];
}

-(IBAction)playAnswerAudio:(id)inSender
{
	[mMCQView stopMedia];
	if ([self canPlayAnswerWordAudio])
		[mProVocDocument playAudio:[self answerAudioKey] ofWord:[self wordForAudio]];
	else if ([self canSpeakAnswer])
		[self speak:[self currentDirection] ? [mCurrentWord sourceWord] : [mCurrentWord targetWord] state:2];
}

-(void)soundDidStartOrStop:(NSNotification *)inNotification
{
	[self willChangeValueForKey:@"questionAudioImage"];
	[self willChangeValueForKey:@"answerAudioImage"];
	[self didChangeValueForKey:@"questionAudioImage"];
	[self didChangeValueForKey:@"answerAudioImage"];
}

@end

@implementation NSScreen (ProVocTester)

static NSMutableArray *sDimWindows = nil;
static int sDimCount = 0;

+(void)dimScreensHidingMenuBar:(BOOL)inHideMenuBar
{
	if (inHideMenuBar)
		HideMenuBar();
	else
		ShowMenuBar();
	if (sDimCount++ == 0) {
		[[ProVocInspector sharedInspector] setInspectorHidden:YES];
		NSEnumerator *enumerator = [[NSScreen screens] objectEnumerator];
		NSScreen *screen;
		while (screen = [enumerator nextObject]) {
			NSRect frameRect = [screen frame];
			NSWindow *window = [[[NSWindow alloc] initWithContentRect:frameRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES] autorelease];
			NSColor *color = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:PVTestBackgroundColor]];
			[window setBackgroundColor:color];
			[window setLevel:NSFloatingWindowLevel];
			[window setHidesOnDeactivate:YES];
			[window orderFront:nil];
			if (!sDimWindows)
				sDimWindows = [[NSMutableArray alloc] initWithCapacity:0];
			[sDimWindows addObject:window];
		}
	}
}

+(void)undimScreens
{
	if (--sDimCount == 0) {
		[sDimWindows makeObjectsPerformSelector:@selector(orderOut:) withObject:nil];
		[sDimWindows removeAllObjects];
		ShowMenuBar();
		[[ProVocInspector sharedInspector] setInspectorHidden:NO];
	}
}

@end

@implementation ProVocBackTranslationPanel

-(BOOL)becomesKeyOnlyIfNeeded
{
	return YES;
}

@end

@implementation ProVocTesterImageView

-(float)preferredWidthForHeight:(float)inHeight
{
	float width = 0;
	NSImage *image = [self image];
	if (image) {
		NSSize imageSize = [image size];
		width = MIN(imageSize.width, MIN(inHeight / imageSize.height * imageSize.width, 2.0 * inHeight));
	}
	return width;
}

@end

@implementation ProVocTesterMovieView

@end

@implementation NSView (Media)

-(void)adjustRightJustifiedView
{
	NSRect viewFrame = [self frame];
	float maxX = NSMinX(viewFrame) - 4;
	if ([self isHidden])
		maxX = NSMaxX(viewFrame);
	viewFrame.origin.x = -1e2;
	viewFrame.size.width = 1e6;
	NSEnumerator *enumerator = [[[self superview] subviews] objectEnumerator];
	NSView *view;
	while (view = [enumerator nextObject])
		if (view != self) {
			NSRect frame = [view frame];
			if (NSIntersectsRect(viewFrame, frame)) {
				float delta = maxX - NSMaxX(frame);
				if (([view autoresizingMask] & NSViewWidthSizable) != 0)
					frame.size.width += delta;
				else
					frame.origin.x += delta;
				[view setFrame:frame];
				[[view superview] setNeedsDisplay:YES];
			}
		}
}

-(void)adjustSize
{
	if ([self tag] == 314)
		[self adjustRightJustifiedView];
	else
		[[self subviews] makeObjectsPerformSelector:_cmd];
}

-(float)preferredWidthForHeight:(float)inHeight
{
	return 0.0;
}

-(void)stopMedia
{
	[[self subviews] makeObjectsPerformSelector:_cmd];
}

@end

@implementation ProVocTesterMediaView

-(float)maxWidth
{
	return [[self superview] bounds].size.width - 250;
}

-(void)setFrameWidth:(float)inWidth
{
	float delta = inWidth - [self frame].size.width;
	if (delta != 0) {
		NSRect frame = [self frame];
		frame.size.width += delta;
		frame.origin.x -= delta;
		[self setFrame:frame];
	}
}

-(void)adjustSize
{
	float height = [self frame].size.height;
	BOOL hidden = NO;
	if ([mLeftView isHidden] && [mRightView isHidden]) {
		hidden = YES;
	} else if ([mLeftView isHidden]) {
		float preferredWidth = [mRightView preferredWidthForHeight:height];
		float k = MIN(1, [self maxWidth] / preferredWidth);
		float width = round(k * preferredWidth);
		NSRect frame = [self frame];
		frame.size.width = width;
		[self setFrameWidth:width];
		frame.origin = NSZeroPoint;
		[mRightView setFrame:frame];
	} else if ([mRightView isHidden]) {
		float preferredWidth = [mLeftView preferredWidthForHeight:height];
		float k = MIN(1, [self maxWidth] / preferredWidth);
		float width = round(k * preferredWidth);
		NSRect frame = [self frame];
		frame.size.width = width;
		[self setFrameWidth:width];
		frame.origin = NSZeroPoint;
		[mLeftView setFrame:frame];
	} else {
		const int margin = 10;
		float leftPreferredWidth = [mLeftView preferredWidthForHeight:height];
		float rightPreferredWidth = [mRightView preferredWidthForHeight:height];
		float preferredWidth = leftPreferredWidth + rightPreferredWidth;
		float k = MIN(1, ([self maxWidth] - margin) / preferredWidth);
		float width = round(k * preferredWidth + margin);
		NSRect frame = [self frame];
		frame.size.width = width;
		[self setFrameWidth:width];
		frame.origin = NSZeroPoint;
		frame.size.width = round(k * leftPreferredWidth);
		[mLeftView setFrame:frame];
		frame.origin.x = NSMaxX(frame) + margin;
		frame.size.width = [self frame].size.width - frame.origin.x;
		[mRightView setFrame:frame];
	}
	[self setHidden:hidden];
	[self adjustRightJustifiedView];
}

-(void)setFrame:(NSRect)inFrame
{
	BOOL changedHeight = inFrame.size.height != [self frame].size.height;
	[super setFrame:inFrame];
	if (changedHeight)
		[self adjustSize];
}

@end

@implementation ProVocMovieViewContainer

-(void)awakeFromNib
{
	if ([NSApp hasQTKit]) {
		NSRect frame = [self bounds];
		ProVocMovieView *movieView = [[ProVocMovieView alloc] initWithFrame:frame];
		[movieView setPreservesAspectRatio:YES];
		[movieView setControllerVisible:YES];
		[movieView setFillColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.0]];
		[movieView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		[movieView bind:@"movie" toObject:mTester withKeyPath:@"nonNilMovie" options:nil];
		[self addSubview:movieView];
		mMovieView = movieView;
		[movieView release];
	}
}

-(float)preferredWidthForHeight:(float)inHeight
{
	if (mMovieView)
		return [mMovieView preferredWidthForHeight:inHeight];
	else
		return 0.0;
}

-(void)setHidden:(BOOL)inFlag
{
	[super setHidden:inFlag];
	if (inFlag)
		[mMovieView pause:nil];
}

-(void)stopMedia
{
	[mMovieView pause:nil];
	[super stopMedia];
}

-(void)dealloc
{
	[mMovieView pause:nil];
	[super dealloc];
}

-(IBAction)play:(id)inSender
{
	[mMovieView play:inSender];
}

-(IBAction)fullScreen:(id)inSender
{
	[mMovieView fullScreen:inSender];
}

@end

//
//  ProVocMCQTester.m
//  ProVoc
//
//  Created by Simon Bovet on 06.10.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import "ProVocMCQTester.h"

#import "ArrayExtensions.h"
#import "ProVocInspector.h"

@interface ProVocTester (Extern)

-(BOOL)canGiveAnswer;
-(int)maxNumberOfChoices;
-(void)stopSpeaking;
-(BOOL)canSpeakLanguage:(NSString *)inLanguage;
-(int)currentDirection;
-(BOOL)ignoreRebound;

@end

@interface ProVocMCQView (Extern)

-(void)playSolutionSound;

@end

@interface ProVocMCQAnswer : NSObject {
	id mAnswer;
	NSString *mSoundMedia;
}

-(id)initWithAnswer:(id)inAnswer soundMedia:(NSString *)inSoundMedia;
-(id)answer;
-(NSString *)soundMedia;

@end

@interface ProVocMediaReference : NSObject {
	NSString *mImageMedia;
	NSString *mMovieMedia;
}

-(id)initWithImageMedia:(NSString *)inImageMedia movieMedia:(NSString *)inMovieMedia;
-(NSString *)imageMedia;
-(NSString *)movieMedia;

@end

@interface ProVocSpokenTextSound : NSObject {
	NSString *mString;
	NSSpeechSynthesizer *mSpeechSynthesizer;
	id mDelegate;
}

-(id)initWithString:(NSString *)inString voice:(id)inVoiceIdentifier;
-(void)setDelegate:(id)inDelegate;
-(BOOL)play;
-(BOOL)stop;

@end

@implementation ProVocMCQTester

-(id)initWithDocument:(ProVocDocument *)inDocument
{
	if (self = [super initWithDocument:inDocument]) {
		mSources = [[NSMutableArray alloc] initWithCapacity:0];
		mTargets = [[NSMutableArray alloc] initWithCapacity:0];
		mLabeledSources = [[NSMutableDictionary alloc] initWithCapacity:10];
		mLabeledTargets = [[NSMutableDictionary alloc] initWithCapacity:10];
	}
	return self;
}

-(void)dealloc
{
	[mAnswerWords release];
	[mSources release];
	[mTargets release];
	[mLabeledSources release];
	[mLabeledTargets release];
	[super dealloc];
}

-(BOOL)handleKeyDownEvent:(NSEvent *)inEvent
{
	if (([inEvent modifierFlags] & (NSCommandKeyMask | NSControlKeyMask)) == 0 && ([[inEvent charactersIgnoringModifiers] isEqualToString:@"0"] || [[inEvent charactersIgnoringModifiers] isEqualToString:@" "])) {
		if ([self canPlayQuestionAudio]) {
			[self playQuestionAudio:nil];
			return YES;
		} else if ([self canPlayQuestionAudio]) {
			[self playQuestionAudio:nil];
			return YES;
		}
	}
	return [super handleKeyDownEvent:inEvent];
}


- (void)beginTestWithWords:(NSArray*)words parameters:(id)inParameters sourceLanguage:(NSString *)inSourceLanguage targetLanguage:(NSString *)inTargetLanguage
{
	[self willChangeValueForKey:@"canGiveAnswer"];
	mNumberOfChoices = [inParameters[@"testMCQNumber"] intValue];
	int columns = 1;
	mImageMCQ = [inParameters[@"imageMCQ"] boolValue];
	if (mImageMCQ) {
		int n = [self maxNumberOfChoices];
		if (n <= 4)
			columns = 2;
		else if (n <= 9)
			columns = 3;
		else
			columns = 4;
	}
	[mMCQView setColumns:columns];
	mDelayedChoices = [inParameters[@"delayedMCQ"] boolValue];
	mDelayingChoices = mDelayedChoices;
	[mMCQView setDisplayAnswers:!mDelayingChoices];
	[[mMCQView window] makeFirstResponder:mMCQView];
	[self didChangeValueForKey:@"canGiveAnswer"];
	[super beginTestWithWords:words parameters:inParameters sourceLanguage:inSourceLanguage targetLanguage:inTargetLanguage];
}

-(void)resumeTestWithParameters:(id)inParameters
{
	[self willChangeValueForKey:@"canGiveAnswer"];
	mNumberOfChoices = [inParameters[@"testMCQNumber"] intValue];
	mDelayedChoices = [inParameters[@"delayedMCQ"] boolValue];
	[self didChangeValueForKey:@"canGiveAnswer"];
	[super resumeTestWithParameters:inParameters];
}

-(NSArray *)allWordsForNotes
{
	return mAnswerWords;
}

-(id)mediaAnswerFromWord:(ProVocWord *)inWord
{
	if (!mImageMCQ)
		return nil;
	NSString *imageMedia = [inWord imageMedia];
	NSString *movieMedia = [inWord movieMedia];
	if (!imageMedia && !movieMedia)
		return nil;
	return [[[ProVocMediaReference alloc] initWithImageMedia:imageMedia movieMedia:movieMedia] autorelease];
}

-(id)sourceAnswerFromWord:(ProVocWord *)inWord
{
	id answer = [self mediaAnswerFromWord:inWord];
	if (!answer)
		answer = [inWord sourceWord];
	NSString *soundMedia = [inWord mediaForAudio:@"Source"];
	if (soundMedia)
		answer = [[[ProVocMCQAnswer alloc] initWithAnswer:answer soundMedia:soundMedia] autorelease];
	return answer;
}

-(id)targetAnswerFromWord:(ProVocWord *)inWord
{
	id answer = [self mediaAnswerFromWord:inWord];
	if (!answer)
		answer = [inWord targetWord];
	NSString *soundMedia = [inWord mediaForAudio:@"Target"];
	if (soundMedia)
		answer = [[[ProVocMCQAnswer alloc] initWithAnswer:answer soundMedia:soundMedia] autorelease];
	return answer;
}

-(void)setAnswerWords:(NSArray *)inWords withParameters:(id)inParameters
{
	mImageMCQ = [inParameters[@"imageMCQ"] boolValue];
	[mAnswerWords release];
	mAnswerWords = [inWords retain];
	NSMutableSet *sources = [NSMutableSet set];
	NSMutableSet *targets = [NSMutableSet set];
	NSEnumerator *enumerator = [inWords objectEnumerator];
	ProVocWord *word;
	while (word = [enumerator nextObject]) {
		NSString *sourceAnswer = [self sourceAnswerFromWord:word];
		NSString *targetAnswer = [self targetAnswerFromWord:word];
		
		[sources addObject:sourceAnswer];
		[targets addObject:targetAnswer];
		
		NSNumber *label = @([word label]);
		NSMutableSet *labeledSources = mLabeledSources[label];
		if (!labeledSources) {
			labeledSources = [NSMutableSet set];
			mLabeledSources[label] = labeledSources;
		}
		[labeledSources addObject:sourceAnswer];
		NSMutableSet *labeledTargets = mLabeledTargets[label];
		if (!labeledTargets) {
			labeledTargets = [NSMutableSet set];
			mLabeledTargets[label] = labeledTargets;
		}
		[labeledTargets addObject:targetAnswer];
	}
	
	[mSources addObjectsFromArray:[sources allObjects]];
	[mTargets addObjectsFromArray:[targets allObjects]];
}

-(NSArray *)possibleAnswers
{
	return mDirection ? mSources : mTargets;
}

-(int)maxNumberOfChoices
{
	int n = 0;
	switch (mRequestedDirection) {
		case 0:
			n = [mTargets count];
			break;
		case 1:
			n = [mSources count];
			break;
		default:
			n = MAX([mSources count], [mTargets count]);
			break;
	}
	return MIN(n, mNumberOfChoices);
}

-(int)numberOfChoices
{
	return MIN([[self possibleAnswers] count], mNumberOfChoices);
}

-(ProVocMCQView *)MCQView
{
	return mMCQView;
}

-(ProVocWord *)chooseRandomWord
{
	ProVocMCQView *mcqView = [self MCQView];
	ProVocWord *word = [super chooseRandomWord];
	[mCurrentWord release];
	mCurrentWord = [word retain];
	NSMutableArray *answers = [NSMutableArray array];
	id answer = mDirection ? [self sourceAnswerFromWord:word] : [self targetAnswerFromWord:word];
	if (!answer)
		answer = @"";
	[answers addObject:answer];
	
	NSSet *preferredAnswerSet = (mDirection ? mLabeledSources : mLabeledTargets)[@([mCurrentWord label])];
	NSArray *preferredAnswers = [[preferredAnswerSet allObjects] shuffledArray];
	int i, n = [preferredAnswers count];
	for (i = 0; i < n && [answers count] < [self numberOfChoices]; i++) {
		NSString *answer = preferredAnswers[i];
		if (![answers containsObject:answer])
			[answers addObject:answer];
	}

	while ([answers count] < [self numberOfChoices]) {
		NSString *answer = [[self possibleAnswers] randomObject];
		if (![answers containsObject:answer])
			[answers addObject:answer];
	}
	id solution = answers[0];
	answers = (id)[answers shuffledArray];
	[mcqView setAnswers:answers solution:solution];
	if (mDelayedChoices) {
		[self willChangeValueForKey:@"canGiveAnswer"];
		[mcqView setDisplayAnswers:NO];
		mDelayingChoices = YES;
		[self didChangeValueForKey:@"canGiveAnswer"];
	}
	return word;
}

-(BOOL)isAnswerFullyCorrect
{
	return YES;
}

-(NSString *)userAnswerString
{
	NSString *answer = [mMCQView selectedAnswer];
	if ([answer isKindOfClass:[NSString class]])
		return answer;
	else
		return nil;
}

- (BOOL)isAnswerCorrect
{
	return [mMCQView isAnswerCorrect];
}

- (NSPanel *)testPanel
{
	return mMCQTestPanel;
}

- (NSString *)testPanelFrameKey
{
	return @"MCQTestPanelFrame";
}

-(int)rows
{
	int rows = ceil((float)[self maxNumberOfChoices] / [mMCQView columns]);
	return rows;
}

-(NSString *)lineHeightKey
{
	return mImageMCQ ? @"Image MCQ Line Height" : @"MCQ Line Height";
}

-(void)restorePanelLayout
{
	NSView *mcqSplitView = [mMCQSplitView subviews][1];
	NSView *otherSplitView = [mMCQSplitView subviews][0];
	NSSize preferredSize = [mcqSplitView frame].size;
	float otherDeltaHeight = 0;
	float otherPreferredHeight = [[NSUserDefaults standardUserDefaults] floatForKey:@"MCQ Other View Height"];
	if (otherPreferredHeight > 0)
		otherDeltaHeight = otherPreferredHeight - [otherSplitView frame].size.height;
	float mcqPreferredLineHeight = [[NSUserDefaults standardUserDefaults] floatForKey:[self lineHeightKey]];
	float mcqDeltaHeight = [mMCQView preferredHeightForNumberOfAnswers:[self numberOfChoices]] - [mMCQView frame].size.height;
	if (mcqPreferredLineHeight > 0)
		mcqDeltaHeight = mcqPreferredLineHeight * [self rows] - [mMCQView frame].size.height;
	preferredSize.height += mcqDeltaHeight;
	NSPanel *panel = [self testPanel];
	NSRect frame = [panel frame];
	frame.size.height += mcqDeltaHeight + otherDeltaHeight;
	[panel setFrame:frame display:YES];

	[mcqSplitView setFrameSize:preferredSize];
	[otherSplitView setFrameSize:NSMakeSize(preferredSize.width, [mMCQSplitView bounds].size.height - [mMCQSplitView dividerThickness] - preferredSize.height)];
	[mMCQSplitView adjustSubviews];
}

-(void)savePanelLayout
{
	NSView *otherSplitView = [mMCQSplitView subviews][0];
	[[NSUserDefaults standardUserDefaults] setFloat:[otherSplitView bounds].size.height forKey:@"MCQ Other View Height"];
	[[NSUserDefaults standardUserDefaults] setFloat:[mMCQView frame].size.height / [self rows] forKey:[self lineHeightKey]];
}

-(BOOL)canGiveAnswer
{
	return [super canGiveAnswer] && !mDelayingChoices;
}

-(NSString *)verifyTitle
{
	if (mDelayingChoices)
		return NSLocalizedString(@"Show Answers Button Title", @"");
	else
		return [super verifyTitle];
}

- (IBAction)giveAnswerTestPanel:(id)inSender
{
	[mMCQView showSolution:nil];
	[super giveAnswerTestPanel:inSender];
}

-(BOOL)MCQView:(ProVocMCQView *)inView shouldSelectAnswer:(id)inAnswer
{
	return [self canGiveAnswer];
}

-(NSString *)stringForAnswer:(id)inAnswer
{
	if ([inAnswer isKindOfClass:[ProVocMCQAnswer class]])
		inAnswer = [inAnswer answer];
	if ([inAnswer isKindOfClass:[ProVocMediaReference class]])
		return nil;
	return inAnswer;
}

-(NSSound *)soundForAnswer:(id)inAnswer
{
	if ([inAnswer isKindOfClass:[ProVocMCQAnswer class]]) {
		NSString *media = [inAnswer soundMedia];
		if (media) {
			NSSound *sound = [mProVocDocument audioForMedia:media];
			if (sound)
				return sound;
		}
	}
	NSString *string = [self stringForAnswer:inAnswer];
	if (mUseSpeechSynthesizer && [string length] > 0 &&
			[self canSpeakLanguage:[self currentDirection] ? [mProVocDocument sourceLanguage] : [mProVocDocument targetLanguage]])
		return [[[ProVocSpokenTextSound alloc] initWithString:string voice:mVoiceIdentifier] autorelease];
	return nil;
}

-(BOOL)shouldPlayAudioForFullAnswer
{
	return NO;
}

-(BOOL)waitForAnswerBeforeTimerElapse
{
	return NO;
}

-(IBAction)playAnswerAudio:(id)inSender
{
	[mMCQView playSound];
}

-(BOOL)autoPlaySound
{
	return mAutoPlayMedia;
}

-(void)stopSound
{
	[self stopSpeaking];
	[[ProVocInspector sharedInspector] stopPlayingSound];
}

-(NSImage *)imageForAnswer:(id)inAnswer
{
	if ([inAnswer isKindOfClass:[ProVocMCQAnswer class]])
		inAnswer = [inAnswer answer];
	if (![inAnswer isKindOfClass:[ProVocMediaReference class]])
		return nil;
	NSString *media = [inAnswer imageMedia];
	if (!media)
		return nil;
	return [mProVocDocument imageForMedia:media];
/*	if (!mImageMCQ) /&/////////// REMOVE mCURRENTWORD SETTING!!!!!
		return nil;
	NSArray *words = [[NSArray arrayWithObject:mCurrentWord] arrayByAddingObjectsFromArray:mAllWords];
	NSEnumerator *enumerator = [words objectEnumerator];
	ProVocWord *word;
	while (word = [enumerator nextObject])
		if ([(mDirection ? [word sourceWord] : [word targetWord]) isEqualToString:inAnswer]) {
			NSImage *image = [mProVocDocument imageOfWord:word];
			if (image)
				return image;
		}
	return nil; */
}

-(id)movieForAnswer:(id)inAnswer
{
	if ([inAnswer isKindOfClass:[ProVocMCQAnswer class]])
		inAnswer = [inAnswer answer];
	if (![inAnswer isKindOfClass:[ProVocMediaReference class]])
		return nil;
	NSString *media = [inAnswer movieMedia];
	if (!media)
		return nil;
	return [mProVocDocument movieForMedia:media];
/*	if (!mImageMCQ)
		return nil;
	NSArray *words = [[NSArray arrayWithObject:mCurrentWord] arrayByAddingObjectsFromArray:mAllWords];
	NSEnumerator *enumerator = [words objectEnumerator];
	ProVocWord *word;
	while (word = [enumerator nextObject])
		if ([(mDirection ? [word sourceWord] : [word targetWord]) isEqualToString:inAnswer]) {
			id movie = [mProVocDocument movieOfWord:word];
			if (movie)
				return movie;
		}
	return nil; */
}

-(IBAction)verifyTestPanel:(id)inSender
{
	if (mDelayingChoices) {
		if ([self ignoreRebound])
			return;
		[self willChangeValueForKey:@"canGiveAnswer"];
		[mMCQView setDisplayAnswers:YES];
		mDelayingChoices = NO;
		[self didChangeValueForKey:@"canGiveAnswer"];
		if (mHidingQuestionText) {
			[self willChangeValueForKey:@"hideQuestion"];
			mHidingQuestionText = NO;
			[self didChangeValueForKey:@"hideQuestion"];
		}
	} else
		[super verifyTestPanel:inSender];
}

-(BOOL)canGiveHint
{
	return NO;
}

@end

@implementation ProVocMCQAnswer

-(id)initWithAnswer:(id)inAnswer soundMedia:(NSString *)inSoundMedia
{
	if (self = [super init]) {
		mAnswer = [inAnswer retain];
		mSoundMedia = [inSoundMedia retain];
	}
	return self;
}

-(void)dealloc
{
	[mAnswer release];
	[mSoundMedia release];
	[super dealloc];
}

-(id)answer
{
	return mAnswer;
}

-(NSString *)soundMedia
{
	return mSoundMedia;
}

-(BOOL)isMedia:(NSString *)inMediaA equalToMedia:(NSString *)inMediaB
{
	if (!inMediaA)
		return !inMediaB;
	else
		return [inMediaA isEqual:inMediaB];
}

-(BOOL)isEqual:(ProVocMCQAnswer *)inObject
{
	if (![inObject isKindOfClass:[ProVocMCQAnswer class]])
		return NO;
	return [[self answer] isEqual:[inObject answer]] && [self isMedia:[self soundMedia] equalToMedia:[inObject soundMedia]];
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"<%@ sound:%@ answer:%@>", NSStringFromClass([self class]), mSoundMedia, mAnswer];
}

-(NSMethodSignature *)methodSignatureForSelector:(SEL)inSelector
{
	if (![self respondsToSelector:inSelector]) {
		id friend = [self answer];
		if ([friend respondsToSelector:inSelector])
			return [friend methodSignatureForSelector:inSelector];
	}
	return [super methodSignatureForSelector:inSelector];
}

-(void)forwardInvocation:(NSInvocation *)inInvocation
{
    SEL selector = [inInvocation selector];
	id friend = [self answer];
    if ([friend respondsToSelector:selector])
        [inInvocation invokeWithTarget:friend];
    else
        [self doesNotRecognizeSelector:selector];
}

@end

@implementation ProVocMediaReference

-(id)initWithImageMedia:(NSString *)inImageMedia movieMedia:(NSString *)inMovieMedia
{
	if (self = [super init]) {
		mImageMedia = [inImageMedia retain];
		mMovieMedia = [inMovieMedia retain];
	}
	return self;
}

-(void)dealloc
{
	[mImageMedia release];
	[mMovieMedia release];
	[super dealloc];
}

-(NSString *)imageMedia
{
	return mImageMedia;
}

-(NSString *)movieMedia
{
	return mMovieMedia;
}

-(BOOL)isMedia:(NSString *)inMediaA equalToMedia:(NSString *)inMediaB
{
	if (!inMediaA)
		return !inMediaB;
	else
		return [inMediaA isEqual:inMediaB];
}

-(BOOL)isEqual:(ProVocMediaReference *)inObject
{
	if (![inObject isKindOfClass:[ProVocMediaReference class]])
		return NO;
	return [self isMedia:[self imageMedia] equalToMedia:[inObject imageMedia]] && [self isMedia:[self movieMedia] equalToMedia:[inObject movieMedia]];
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"<%@ image:%@ movie:%@>", NSStringFromClass([self class]), mImageMedia, mMovieMedia];
}

@end

@implementation ProVocSpokenTextSound

-(id)initWithString:(NSString *)inString voice:(id)inVoiceIdentifier
{
	if (self = [super init]) {
		mString = [inString retain];
		mSpeechSynthesizer = [[NSSpeechSynthesizer alloc] initWithVoice:inVoiceIdentifier];
		if (!mSpeechSynthesizer)
			mSpeechSynthesizer = [[NSSpeechSynthesizer alloc] initWithVoice:nil];
		[mSpeechSynthesizer setDelegate:self];
	}
	return self;
}

-(void)dealloc
{
	[mString release];
	[mSpeechSynthesizer release];
	[super dealloc];
}

-(void)setDelegate:(id)inDelegate
{
	mDelegate = inDelegate;
}

-(BOOL)play
{
	[mSpeechSynthesizer stopSpeaking]; // ++++ v4.2.2 ++++
	return [mSpeechSynthesizer startSpeakingString:mString];
}

-(BOOL)stop
{
	[mSpeechSynthesizer stopSpeaking];
	return YES;
}

-(void)speechSynthesizer:(NSSpeechSynthesizer *)inSynthesizer didFinishSpeaking:(BOOL)inFlag
{
	[mDelegate sound:(id)self didFinishPlaying:inFlag];
}

@end


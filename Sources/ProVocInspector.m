//
//  ProVocInspector.m
//  ProVoc
//
//  Created by Simon Bovet on 29.03.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ProVocInspector.h"

#import "ProVocDocument+Lists.h"
#import "ProVocPage.h"
#import "ProVocChapter.h"
#import "ProVocApplication.h"
#import "ProVocImageView.h"
#import "StringExtensions.h"
#import "WindowExtensions.h"
#import "BezierPathExtensions.h"
#import "AppleScriptExtensions.h"
#import <ARLeopardSoundRecorder/ARLeopardSoundRecorderController.h>
#import <ARSequenceGrabber/ARSequenceGrabber.h>
#import <QTKit/QTKit.h>

@implementation ProVocInspector

+(void)initialize
{
	NSArray *keys;
	keys = @[@"language"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"sourceLanguageCaption"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"targetLanguageCaption"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"sourceFontFamilyName"];
	keys = @[@"word"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"hasSelection"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"sourceText"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"targetText"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"commentText"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"image"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"movie"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"canModifyText"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"canModifyImage"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"canModifyMovie"];
	keys = @[@"word", @"playing"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"canRecordAudio"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"canPlaySourceAudio"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"canPlayTargetAudio"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"playSourceAudioIcon"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"playTargetAudioIcon"];
	keys = @[@"sourceFontFamilyName"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"sourceFontSize"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"sourceWritingDirection"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"targetFontFamilyName"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"targetFontSize"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"targetWritingDirection"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"commentFontFamilyName"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"commentFontSize"];
	[self setKeys:keys triggerChangeNotificationsForDependentKey:@"commentWritingDirection"];
}

+(ProVocInspector *)sharedInspector
{
	static ProVocInspector *sharedInspector = nil;
	if (!sharedInspector)
		sharedInspector = [[self alloc] initWithWindowNibName:@"ProVocInspector"];
	return sharedInspector;
}

-(BOOL)shouldDisplayOnStartup
{
	return NO;
}

-(void)addViews
{
	[self addView:mTextView withName:NSLocalizedString(@"Text Inspector View", @"") identifier:@"Text" openByDefault:NO];
	[self addView:mAudioView withName:NSLocalizedString(@"Audio Inspector View", @"") identifier:@"Audio" openByDefault:YES];
	[self addView:mImageView withName:NSLocalizedString(@"Image Inspector View", @"") identifier:@"Image" openByDefault:YES];
	[self addView:mMovieView withName:NSLocalizedString(@"Movie Inspector View", @"") identifier:@"Movie" openByDefault:YES];
		
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.sourceFontFamilyName" options:NSKeyValueObservingOptionNew context:nil];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.sourceFontSize" options:NSKeyValueObservingOptionNew context:nil];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.sourceWritingDirection" options:NSKeyValueObservingOptionNew context:nil];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.targetFontFamilyName" options:NSKeyValueObservingOptionNew context:nil];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.targetFontSize" options:NSKeyValueObservingOptionNew context:nil];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.targetWritingDirection" options:NSKeyValueObservingOptionNew context:nil];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.commentFontFamilyName" options:NSKeyValueObservingOptionNew context:nil];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.commentFontSize" options:NSKeyValueObservingOptionNew context:nil];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.commentWritingDirection" options:NSKeyValueObservingOptionNew context:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanup:) name:NSApplicationWillTerminateNotification object:nil];
	[[self window] setDelegate:self];
}

-(float)scaleFactor
{
	if ([NSApp systemVersion] >= 0x1040)
		return [[self window] userSpaceScaleFactor];
	else
		return 1.0;
}

-(void)windowDidBecomeKey:(id)inSender
{
	[mWordMovieView setNeedsDisplay:YES];
}

-(void)windowDidResignKey:(id)inSender
{
	[mWordMovieView setNeedsDisplay:YES];
}

-(void)observeValueForKeyPath:(NSString *)inKeyPath ofObject:(id)inObject change:(NSDictionary *)inChange context:(void *)inContext
{
	[self willChangeValueForKey:@"sourceFontFamilyName"];
	[self didChangeValueForKey:@"sourceFontFamilyName"];
}

-(void)setInspectorHidden:(BOOL)inHide
{
	[[self window] setAlphaValue:inHide ? 0.0 : 1.0];
}

-(void)setPreferredDisplayState:(BOOL)inDisplay
{
	if (mPreferredDisplayState != inDisplay)
		if (inDisplay) {
			if ([[NSUserDefaults standardUserDefaults] boolForKey:@"InspectorPreferredVisible"] && ![self isVisible])
				[self toggle];
		} else {
			[[NSUserDefaults standardUserDefaults] setBool:[self isVisible] forKey:@"InspectorPreferredVisible"];
			if ([self isVisible])
				[self toggle];
		}
	mPreferredDisplayState = inDisplay;
}

-(void)cleanup:(id)inSender
{
	if (mPreferredDisplayState)
		[[NSUserDefaults standardUserDefaults] setBool:[self isVisible] forKey:@"InspectorPreferredVisible"];
}

-(void)setDocument:(ProVocDocument *)inDocument
{
	if (mDocument != inDocument) {
		[self willChangeValueForKey:@"language"];
		[self willChangeValueForKey:@"sourceFontFamilyName"];
		[mDocument release];
		mDocument = [inDocument retain];
		[self didChangeValueForKey:@"language"];
		[self didChangeValueForKey:@"sourceFontFamilyName"];
		[self setSelectedWords:nil];
	}
}

-(void)setSelectedWords:(NSArray *)inWords
{
	[self willChangeValueForKey:@"word"];
	if (![mSelectedWords isEqual:inWords]) {
		[mSelectedWords release];
		mSelectedWords = [inWords retain];
	}
	[self didChangeValueForKey:@"word"];
}

-(void)documentParameterDidChange:(ProVocDocument *)inDocument
{
	if (mDocument == inDocument) {
		[self willChangeValueForKey:@"language"];
		[self didChangeValueForKey:@"language"];
		[self willChangeValueForKey:@"sourceFontFamilyName"];
		[self didChangeValueForKey:@"sourceFontFamilyName"];
	}
}

-(void)selectedWordParameterDidChange:(ProVocWord *)inWord
{
	[self willChangeValueForKey:@"word"];
	[self didChangeValueForKey:@"word"];
}

-(ProVocWord *)selectedWord
{
	if ([mSelectedWords count] == 1)
		return mSelectedWords[0];
	else
		return nil;
}

-(void)playAudio:(NSString *)inKey
{
	if (!mWordsToPlaySound)
		mWordsToPlaySound = [[NSMutableArray alloc] initWithCapacity:0];
	[mWordsToPlaySound setArray:mSelectedWords];
	[mSoundToPlay autorelease];
	mSoundToPlay = [inKey retain];
	[self playNextSound];
}

-(IBAction)playSourceAudio:(id)inSender
{
	[self playAudio:@"Source"];
}

-(IBAction)playTargetAudio:(id)inSender
{
	[self playAudio:@"Target"];
}

-(BOOL)canModifyText
{
	return [self selectedWord] != nil;
}

-(NSString *)sourceText
{
	return [[self selectedWord] sourceWord];
}

-(void)setSourceText:(NSString *)inText
{
	ProVocWord *word = [self selectedWord];
	[mDocument willChangeWord:word];
	[word setSourceWord:inText];
	[mDocument visibleWordsDidChange];
	[mDocument didChangeWord:word];
}

-(NSString *)targetText
{
	return [[self selectedWord] targetWord];
}

-(void)setTargetText:(NSString *)inText
{
	ProVocWord *word = [self selectedWord];
	[mDocument willChangeWord:word];
	[word setTargetWord:inText];
	[mDocument visibleWordsDidChange];
	[mDocument didChangeWord:word];
}

-(NSString *)commentText
{
	return [[self selectedWord] comment];
}

-(void)setCommentText:(NSString *)inText
{
	ProVocWord *word = [self selectedWord];
	[mDocument willChangeWord:word];
	[word setComment:inText];
	[mDocument visibleWordsDidChange];
	[mDocument didChangeWord:word];
}

-(NSString *)sourceFontFamilyName
{
	return [mDocument sourceFontFamilyName];
}

-(float)sourceFontSize
{
	return [mDocument sourceFontSize];
}

-(NSWritingDirection)sourceWritingDirection
{
	return [mDocument sourceWritingDirection];
}

-(NSString *)targetFontFamilyName
{
	return [mDocument targetFontFamilyName];
}

-(float)targetFontSize
{
	return [mDocument targetFontSize];
}

-(NSWritingDirection)targetWritingDirection
{
	return [mDocument targetWritingDirection];
}

-(NSString *)commentFontFamilyName
{
	return [mDocument commentFontFamilyName];
}

-(float)commentFontSize
{
	return [mDocument commentFontSize];
}

-(NSWritingDirection)commentWritingDirection
{
	return [mDocument commentWritingDirection];
}

-(BOOL)canModifyImage
{
	return [self selectedWord] != nil;
}

-(BOOL)canRemoveImage
{
	NSEnumerator *enumerator = [mSelectedWords objectEnumerator];
	ProVocWord *word;
	while (word = [enumerator nextObject])
		if ([word imageMedia])
			return YES;
	return NO;
}

-(BOOL)canModifyMovie
{
	return [self selectedWord] != nil;
}

-(BOOL)canRemoveMovie
{
	NSEnumerator *enumerator = [mSelectedWords objectEnumerator];
	ProVocWord *word;
	while (word = [enumerator nextObject])
		if ([word movieMedia])
			return YES;
	return NO;
}

-(BOOL)hasSelection
{
	return [mSelectedWords count] > 0;
}

-(BOOL)validateMenuItem:(NSMenuItem *)inItem
{
	SEL action = [inItem action];
	if (action == @selector(importImage:) || action == @selector(importMovie:))
		return [self hasSelection];
	if (action == @selector(removeImage:) || action == @selector(exportImage:))
		return [self canRemoveImage];
	if (action == @selector(removeMovie:) || action == @selector(exportMovie:))
		return [self canRemoveMovie];
	if (action == @selector(importSourceAudio:) || action == @selector(importTargetAudio:))
		return [self hasSelection];
	if (action == @selector(removeSourceAudio:) || action == @selector(exportSourceAudio:))
		return [self canRemoveAudio:@"Source"];
	if (action == @selector(removeTargetAudio:) || action == @selector(exportTargetAudio:))
		return [self canRemoveAudio:@"Target"];
	return YES;
}

-(void)importAudio:(NSString *)inKey
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	if ([openPanel runModalForTypes:[NSSound soundUnfilteredFileTypes]] == NSOKButton) {
		NSEnumerator *enumerator = [mSelectedWords objectEnumerator];
		ProVocWord *word;
		while (word = [enumerator nextObject])
			[mDocument setAudioFile:[openPanel filename] forKey:inKey ofWord:word];
	}
}

-(IBAction)importSourceAudio:(id)inSender
{
	[self importAudio:@"Source"];
}

-(IBAction)importTargetAudio:(id)inSender
{
	[self importAudio:@"Target"];
}

-(void)exportAudio:(NSString *)inKey
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setTitle:NSLocalizedString(@"Export Audio Panel Title", @"")];
	[openPanel setPrompt:NSLocalizedString(@"Export Audio Panel Prompt", @"")];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	if ([openPanel runModalForTypes:nil] == NSOKButton) {
		NSString *nameSelectorName = [inKey isEqual:@"Source"] ? @"sourceWord" : @"targetWord";
		NSString *otherNameSelectorName = [inKey isEqual:@"Source"] ? @"targetWord" : @"sourceWord";
		NSDictionary *info = @{@"Directory": [openPanel filename], @"Key": inKey, @"NameSelectorName": nameSelectorName, @"OtherNameSelectorName": otherNameSelectorName, @"Document": mDocument};
		[mSelectedWords makeObjectsPerformSelector:@selector(exportAudio:) withObject:info];
	}
}

-(IBAction)exportSourceAudio:(id)inSender
{
	[self exportAudio:@"Source"];
}

-(IBAction)exportTargetAudio:(id)inSender
{
	[self exportAudio:@"Target"];
}

-(void)removeAudio:(NSString *)inKey language:(NSString *)inLanguage
{
	[mDocument willChangeData];
	[self willChangeValueForKey:@"word"];
	[mSelectedWords makeObjectsPerformSelector:@selector(removeAudio:) withObject:inKey];
	[self didChangeValueForKey:@"word"];
	[mDocument visibleWordsDidChange];
	[mDocument didChangeData];
}

-(IBAction)removeSourceAudio:(id)inSender
{
	[self removeAudio:@"Source" language:[mDocument sourceLanguage]];
}

-(IBAction)removeTargetAudio:(id)inSender
{
	[self removeAudio:@"Target" language:[mDocument targetLanguage]];
}

-(ARLeopardSoundRecorderController *)sharedSoundRecorderController
{
	if ([NSApp systemVersion] < 0x1050) {
		int result = NSRunAlertPanel(NSLocalizedString(@"Leopard Only Feature Title", @""), NSLocalizedString(@"Leopard Only Feature Message", @""), NSLocalizedString(@"OK", @""), NSLocalizedString(@"Leopard Only Feature Download Button", @""), nil);
		if (result == NSAlertAlternateReturn) {
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"Leopard Only Feature Download URL", @"")]];
		}
		return nil;
	} else
		return [ARLeopardSoundRecorderController sharedController];
}

-(void)recordAudio:(NSString *)inKey
{
	if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) == 0)
		[self recordAudioImmediately:inKey];
	else if ([[self sharedSoundRecorderController] runModal]) {
		ProVocWord *word = [self selectedWord];
		[mDocument willChangeWord:word];
		[mDocument setAudioFile:[[self sharedSoundRecorderController] recordedFile] forKey:inKey ofWord:word];
		[mDocument didChangeWord:word];
	}
}

-(IBAction)recordSourceAudio:(id)inSender
{
	[self recordAudio:@"Source"];
}

-(IBAction)recordTargetAudio:(id)inSender
{
	[self recordAudio:@"Target"];
}

-(IBAction)soundInput:(id)inSender
{
	[[self sharedSoundRecorderController] settings:inSender];
}

-(IBAction)importImage:(id)inSender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	if ([openPanel runModalForTypes:[NSImage imageUnfilteredFileTypes]] == NSOKButton) {
		NSEnumerator *enumerator = [mSelectedWords objectEnumerator];
		ProVocWord *word;
		while (word = [enumerator nextObject])
			[mDocument setImageFile:[openPanel filename] ofWord:word];
	}
}

-(IBAction)exportImage:(id)inSender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setTitle:NSLocalizedString(@"Export Image Panel Title", @"")];
	[openPanel setPrompt:NSLocalizedString(@"Export Image Panel Prompt", @"")];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	if ([openPanel runModalForTypes:nil] == NSOKButton) {
		NSDictionary *info = @{@"Directory": [openPanel filename], @"Document": mDocument};
		[mSelectedWords makeObjectsPerformSelector:@selector(exportImage:) withObject:info];
	}
}

-(IBAction)removeImage:(id)inSender
{
	[mDocument willChangeData];
	[self willChangeValueForKey:@"word"];
	[mSelectedWords makeObjectsPerformSelector:@selector(removeImage)];
	[self didChangeValueForKey:@"word"];
	[mDocument visibleWordsDidChange];
	[mDocument didChangeData];
}

static BOOL sRecording = NO;

-(IBAction)recordImage:(id)inSender
{
	if (!sRecording) {
		sRecording = YES;
		NSImage *image = [[ARSequenceGrabber sharedGrabber] captureImage];
		sRecording = NO;
		if (image) {
			NSEnumerator *enumerator = [mSelectedWords objectEnumerator];
			ProVocWord *word;
			while (word = [enumerator nextObject])
				[mDocument setImage:image ofWord:word];
		}
	}
}

-(IBAction)importMovie:(id)inSender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	if ([openPanel runModalForTypes:[QTMovie movieUnfilteredFileTypes]] == NSOKButton) {
		NSEnumerator *enumerator = [mSelectedWords objectEnumerator];
		ProVocWord *word;
		while (word = [enumerator nextObject])
			[mDocument setMovieFile:[openPanel filename] ofWord:word];
	}
}

-(IBAction)exportMovie:(id)inSender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setTitle:NSLocalizedString(@"Export Movie Panel Title", @"")];
	[openPanel setPrompt:NSLocalizedString(@"Export Movie Panel Prompt", @"")];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	if ([openPanel runModalForTypes:nil] == NSOKButton) {
		NSDictionary *info = @{@"Directory": [openPanel filename], @"Document": mDocument};
		[mSelectedWords makeObjectsPerformSelector:@selector(exportMovie:) withObject:info];
	}
}

-(IBAction)removeMovie:(id)inSender
{
	[mDocument willChangeData];
	[self willChangeValueForKey:@"word"];
	[mSelectedWords makeObjectsPerformSelector:@selector(removeMovie)];
	[self didChangeValueForKey:@"word"];
	[mDocument visibleWordsDidChange];
	[mDocument didChangeData];
}

-(IBAction)recordMovie:(id)inSender
{
	if (!sRecording) {
		sRecording = YES;
		NSString *file = [[ARSequenceGrabber sharedGrabber] captureMovie];
		sRecording = NO;
		if (file) {
			NSEnumerator *enumerator = [mSelectedWords objectEnumerator];
			ProVocWord *word;
			while (word = [enumerator nextObject])
				[mDocument setMovieFile:file ofWord:word];
		}
	}
}

-(BOOL)handleKeyDownEvent:(NSEvent *)inEvent
{
	if (([inEvent modifierFlags] & NSControlKeyMask) != 0)
		return NO;
	if ([mDocument testIsRunning])
		return NO;
	BOOL record = (([inEvent modifierFlags] & NSCommandKeyMask) != 0) == ![[NSUserDefaults standardUserDefaults] boolForKey:@"NoShiftRecord"];
	switch ([inEvent keyCode]) {
		case 122: // F1
			if (!record)
				[self playSourceAudio:nil];
			else if ([self canRecordAudio])
				[self recordAudioImmediately:@"Source"];
			return YES;
		case 120: // F2
			if (!record)
				[self playTargetAudio:nil];
			else if ([self canRecordAudio])
				[self recordAudioImmediately:@"Target"];
			return YES;
		case 99: // F3
			if (!record)
				[[mDocument imageOfWord:[self selectedWord]] displayInFullSize];
			else if ([self canModifyImage])
				[self recordImage:nil];
			return YES;
		case 118: // F4
			if (!record) {
				if (![self isViewVisibleWithIdentifier:@"Movie"] || ([inEvent modifierFlags] & (NSShiftKeyMask | NSAlternateKeyMask)) != 0)
					[[mDocument movieOfWord:[self selectedWord]] displayInFullSize];
				else
					[mWordMovieView play:nil];
			} else if ([self canModifyMovie])
				[self recordMovie:nil];
			return YES;
		default:
			return NO;
	}
}

-(NSString *)sourceLanguageCaption
{
	return [mDocument sourceLanguageCaption];
}

-(NSString *)targetLanguageCaption
{
	return [mDocument targetLanguageCaption];
}

-(BOOL)canPlayAudio:(NSString *)inKey
{
	NSEnumerator *enumerator = [mSelectedWords objectEnumerator];
	ProVocWord *word;
	while (word = [enumerator nextObject])
		if ([word canPlayAudio:inKey])
			return YES;
	return NO;
}

-(BOOL)canPlaySourceAudio
{
	return [self canPlayAudio:@"Source"];
}

-(BOOL)canPlayTargetAudio
{
	return [self canPlayAudio:@"Target"];
}

-(NSImage *)playSourceAudioIcon
{
	if ([mSoundToPlay isEqual:@"Source"] || [self selectedWord] == mPlayingSoundWord && [mPlayingSoundKey isEqual:@"Source"])
		return [NSImage imageNamed:@"SpeakerOn"];
	else
		return [NSImage imageNamed:@"SpeakerOff"];
}

-(NSImage *)playTargetAudioIcon
{
	if ([mSoundToPlay isEqual:@"Target"] || [self selectedWord] == mPlayingSoundWord && [mPlayingSoundKey isEqual:@"Target"])
		return [NSImage imageNamed:@"SpeakerOn"];
	else
		return [NSImage imageNamed:@"SpeakerOff"];
}

-(NSImage *)image
{
	if (![self isViewVisibleWithIdentifier:@"Image"])
		return nil;
	else
		return [mDocument imageOfWord:[self selectedWord]];
}

-(void)imageView:(ProVocImageView *)inImageView didReceiveDraggedImageFile:(NSString *)inFile
{
	ProVocWord *word = [self selectedWord];
	[mDocument willChangeWord:word];
	[mDocument setImageFile:inFile ofWord:word];
	[mDocument didChangeWord:word];
}

-(id)movie
{
	if (![self isViewVisibleWithIdentifier:@"Movie"])
		return nil;
	else
		return [mDocument movieOfWord:[self selectedWord]];
}

-(void)viewWithIdentifierWillBecomeVisible:(NSString *)inIdentifier
{
	if ([inIdentifier isEqualToString:@"Image"]) {
		[self willChangeValueForKey:@"image"];
		[self didChangeValueForKey:@"image"];
	}
	else if ([inIdentifier isEqualToString:@"Movie"]) {
		[self willChangeValueForKey:@"movie"];
		[self didChangeValueForKey:@"movie"];
	}
}

@end

@implementation ProVocInspector (Media)

-(void)removeMediaOtherThan:(NSSet *)inUsedMedia
{
	NSAppleEventDescriptor *media = [[[NSAppleEventDescriptor alloc] initListDescriptor] autorelease];
	NSEnumerator *enumerator = [inUsedMedia objectEnumerator];
	NSString *name;
	int index = 1;
	while (name = [enumerator nextObject])
		[media insertDescriptor:[NSAppleEventDescriptor descriptorWithString:name] atIndex:index++];

	NSString *scriptPath = [[NSBundle mainBundle] pathForResource:@"iPod" ofType:@"scpt"];
	NSURL *scriptURL = [NSURL fileURLWithPath:scriptPath];

	NSDictionary *errorInfo = nil;
	NSAppleScript *script = [[[NSAppleScript alloc] initWithContentsOfURL:scriptURL error:&errorInfo] autorelease];
	if (!script || errorInfo)
		goto error;
	NSAppleEventDescriptor *arguments = [[[NSAppleEventDescriptor alloc] initListDescriptor] autorelease];
	[arguments insertDescriptor:media atIndex:1];

	errorInfo = nil;
	NSAppleEventDescriptor *result = [script callHandler:@"delete_all_provoc_files" withArguments:arguments errorInfo:&errorInfo];
	int scriptResult = [result int32Value];
	if (errorInfo || scriptResult != 0)
		goto error;
	
	return;
error:
	NSBeep();
}

@end

@implementation ProVocInspector (Audio)

-(BOOL)canRecordAudio
{
	return [self selectedWord] != nil;
}

-(BOOL)canRemoveAudio:(NSString *)inKey
{
	NSEnumerator *enumerator = [mSelectedWords objectEnumerator];
	ProVocWord *word;
	while (word = [enumerator nextObject])
		if ([word canPlayAudio:inKey])
			return YES;
	return NO;
}

-(void)stopPlayingSound
{
	[self willChangeValueForKey:@"playing"];
	[mPlayingSound stop];
	[mPlayingSound release];
	mPlayingSound = nil;
	[mPlayingSoundKey release];
	mPlayingSoundKey = nil;
	[mPlayingSoundWord release];
	mPlayingSoundWord = nil;	
	[self didChangeValueForKey:@"playing"];
}

-(void)playSoundFile:(NSString *)inSoundFile forAudio:(NSString *)inKey ofWord:(ProVocWord *)inWord
{
	BOOL play = ![self isPlayingAudio:inKey ofWord:inWord];
	[self stopPlayingSound];
	if (play) {
		[self willChangeValueForKey:@"playing"];
		mPlayingSound = [[NSSound alloc] initWithContentsOfFile:inSoundFile byReference:YES];
		mPlayingSoundKey = [inKey retain];
		mPlayingSoundWord = [inWord retain];
		[mPlayingSound setDelegate:self];
		if (![mPlayingSound play])
			[self stopPlayingSound];
		[[NSNotificationCenter defaultCenter] postNotificationName:ProVocSoundDidStartPlayingNotification object:nil];
		[self didChangeValueForKey:@"playing"];
	}
}

-(BOOL)isPlayingAudio:(NSString *)inKey ofWord:(ProVocWord *)inWord
{
	return mPlayingSoundWord == inWord && [mPlayingSoundKey isEqual:inKey];
}

-(BOOL)playNextSound
{
	while ([mWordsToPlaySound count] > 0) {
		ProVocWord *word = [[mWordsToPlaySound[0] retain] autorelease];
		[mWordsToPlaySound removeObjectAtIndex:0];
		if ([word canPlayAudio:mSoundToPlay]) {
			[mDocument playAudio:mSoundToPlay ofWord:word];
			return YES;
		}
	}
	[mSoundToPlay release];
	mSoundToPlay = nil;
	return NO;
}

-(void)sound:(NSSound *)inSound didFinishPlaying:(BOOL)inSuccess
{
	if (![self playNextSound]) {
		[self stopPlayingSound];
		[[NSNotificationCenter defaultCenter] postNotificationName:ProVocSoundDidStopPlayingNotification object:nil];
	}
}

-(void)setAudio:(NSString *)inKey file:(NSString *)inFile
{
	ProVocWord *word = [self selectedWord];
	[mDocument willChangeWord:word];
	[mDocument setAudioFile:inFile forKey:inKey ofWord:word];
	[mDocument didChangeWord:word];
}

-(void)recordAudioImmediately:(NSString *)inKey
{
	if (![self canRecordAudio])
		return;
	[self stopPlayingSound];
	NSString *soundFile = [[self sharedSoundRecorderController] singleShotRecord];
	if (!soundFile)
		return;
	[self setAudio:inKey file:soundFile];
	[self performSelector:@selector(playAudio:) withObject:inKey afterDelay:0.25];
}

@end

@implementation ProVocInspector (Image)

-(void)setImage:(NSImage *)inImage
{
	ProVocWord *word = [self selectedWord];
	[mDocument willChangeWord:word];
	[mDocument setImage:inImage ofWord:word];
	[mDocument didChangeWord:word];
}

-(void)setImageFile:(NSString *)inFile
{
	ProVocWord *word = [self selectedWord];
	[mDocument willChangeWord:word];
	[mDocument setImageFile:inFile ofWord:word];
	[mDocument didChangeWord:word];
}

@end

@implementation ProVocInspector (Movie)

-(void)setMovieFile:(NSString *)inFile
{
	ProVocWord *word = [self selectedWord];
	[mDocument willChangeWord:word];
	[mDocument setMovieFile:inFile ofWord:word];
	[mDocument didChangeWord:word];
}

@end

@implementation ProVocDocument (Media)

-(NSString *)mediaPathInBundle:(NSString *)inPath
{
	NSString *path = [inPath ? inPath : [self fileName] stringByAppendingPathComponent:@"Media"];
	BOOL isDir;
	if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir || [[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil])
		return path;
	return nil;
}

-(NSString *)mediaPathInBundle
{
	return [self mediaPathInBundle:nil];
}

-(NSString *)temporaryDirectory
{
	static NSString *directory = nil;
	if (!directory) {
		int timeStamp = (int)[NSDate timeIntervalSinceReferenceDate];
		int random = rand() % 0x10000;
		directory = [[NSString alloc] initWithFormat:@"/tmp/ProVoc%08X%04X", timeStamp, random];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanup:) name:NSApplicationWillTerminateNotification object:nil];
	}
	BOOL isDir;
	if (!([[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isDir] && isDir || [[NSFileManager defaultManager] createDirectoryAtPath:directory attributes:nil]))
		[NSException raise:@"ProVocInspectorException" format:@"Error creating path %@", directory];
	return directory;
}

-(void)cleanup:(NSNotification *)inNotification
{
	NSString *directory = [self temporaryDirectory];
	if ([directory hasPrefix:@"/tmp/ProVoc"])
		[[NSFileManager defaultManager] removeFileAtPath:directory handler:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationWillTerminateNotification object:nil];
}

-(NSString *)pathForMediaFile:(NSString *)inName
{
	NSString *path;
	path = [[self mediaPathInBundle:nil] stringByAppendingPathComponent:inName];
	if ([[NSFileManager defaultManager] fileExistsAtPath:path])
		return path;
	path = [[self temporaryDirectory] stringByAppendingPathComponent:inName];
	if ([[NSFileManager defaultManager] fileExistsAtPath:path])
		return path;
	if ([NSApp systemVersion] >= 0x1040) {
		NSURL *url = [self autosavedContentsFileURL];
		if (url) {
			path = [[self mediaPathInBundle:[url path]] stringByAppendingPathComponent:inName];
			if ([[NSFileManager defaultManager] fileExistsAtPath:path])
				return path;
		}
	}
	return nil;
}

-(void)moveUsedMediaFromFile:(NSString *)inPath toTemporaryFolderForSaveOperation:(NSSaveOperationType)inSaveOperationType
{
	if (![self mediaPathInBundle:inPath])
		return;
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSEnumerator *enumerator = [[self allWords] objectEnumerator];
	ProVocWord *word;
	while (word = [enumerator nextObject]) {
		NSMutableDictionary *mediaDictionary = [word mediaDictionary];
		NSEnumerator *mediaEnumerator = [mediaDictionary objectEnumerator];
		NSString *mediaName;
		while (mediaName = [mediaEnumerator nextObject]) {
			NSString *source = [[self mediaPathInBundle:inPath] stringByAppendingPathComponent:mediaName];
			if ([NSApp systemVersion] >= 0x1040 && ![fileManager fileExistsAtPath:source]) {
				NSURL *url = [self autosavedContentsFileURL];
				if (url)
					source = [[self mediaPathInBundle:[url path]] stringByAppendingPathComponent:mediaName];
			}
			if ([fileManager fileExistsAtPath:source]) {
				NSString *destination = [[self temporaryDirectory] stringByAppendingPathComponent:mediaName];
				BOOL ok;
				if ([fileManager fileExistsAtPath:destination])
					ok = YES;
				else if (inSaveOperationType == NSSaveOperation)
					ok = [fileManager movePath:source toPath:destination handler:nil];
				else
					ok = [fileManager copyPath:source toPath:destination handler:nil];
				if (!ok)
					[NSException raise:@"ProVocInspectorException" format:@"Error moving out %@ to %@", source, destination];
			}
		}
	}
}

-(void)moveUsedMediaIntoBundle:(NSString *)inPath
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSEnumerator *enumerator = [[self allWords] objectEnumerator];
	ProVocWord *word;
	while (word = [enumerator nextObject]) {
		NSMutableDictionary *mediaDictionary = [word mediaDictionary];
		NSEnumerator *mediaEnumerator = [mediaDictionary objectEnumerator];
		NSString *mediaName;
		while (mediaName = [mediaEnumerator nextObject]) {
			NSString *source = [[self temporaryDirectory] stringByAppendingPathComponent:mediaName];
			if ([fileManager fileExistsAtPath:source]) {
				NSString *destination = [[self mediaPathInBundle:inPath] stringByAppendingPathComponent:mediaName];
				BOOL ok;
				if (mAutosaving)
					ok = [fileManager fileExistsAtPath:destination] || [fileManager copyPath:source toPath:destination handler:nil];
				else
					ok = [fileManager movePath:source toPath:destination handler:nil];
				if (!ok)
					[NSException raise:@"ProVocInspectorException" format:@"Error moving back %@ to %@", source, destination];
			}
		}
	}
}

-(void)exportMedia:(NSString *)inName toFile:(NSString *)inDestination
{
	NSString *source = [self pathForMediaFile:inName];
	if (source) {
		NSString *destination = inDestination;
		while ([[NSFileManager defaultManager] fileExistsAtPath:destination]) {
			NSString *directory = [destination stringByDeletingLastPathComponent];
			NSString *name = [[destination lastPathComponent] stringByDeletingPathExtension];
			NSString *extension = [destination pathExtension];
			
			NSMutableArray *names = [NSMutableArray array];
			NSEnumerator *enumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:directory] objectEnumerator];
			NSString *file;
			while (file = [enumerator nextObject])
				if ([[file pathExtension] isEqualToString:extension])
					[names addObject:[file stringByDeletingPathExtension]];
			
			name = [name nameOfCopyWithExistingNames:names];
			
			destination = [directory stringByAppendingPathComponent:[name stringByAppendingPathExtension:extension]];
		}
		[[NSFileManager defaultManager] copyPath:source toPath:destination handler:nil];
	}
}

-(void)displayMediaOfWord:(ProVocWord *)inWord
{
	id movie = [self movieOfWord:inWord];
	if (movie)
		[movie displayInFullSize];
	else {
		NSImage *image = [self imageOfWord:inWord];
		if (image)
			[image displayInFullSize];
	}
}

@end

@implementation ProVocDocument (Image)

-(NSString *)newImageFileName
{
	return [NSString newMediaFileName:@"Image"];
}

-(void)setImageFile:(NSString *)inFileName ofWord:(ProVocWord *)inWord
{
	NSString *directory = [self temporaryDirectory];
	NSString *mediaName = [[self newImageFileName] stringByAppendingPathExtension:[inFileName pathExtension]];
	NSString *copyPath = [directory stringByAppendingPathComponent:mediaName];
	if (![[NSFileManager defaultManager] copyPath:inFileName toPath:copyPath handler:nil])
		[NSException raise:@"ProVocInspectorException" format:@"Could not copy image file %@ to %@", inFileName, copyPath];
	[self willChangeWord:inWord];
	[inWord setImageMedia:[copyPath lastPathComponent]];
	[self visibleWordsDidChange];
	[self selectedWordParameterDidChange:inWord];
	[self didChangeWord:inWord];
}

-(void)setImage:(NSImage *)inImage ofWord:(ProVocWord *)inWord
{
	if (!inImage) {
		[self willChangeWord:inWord];
		[inWord removeImage];
		[self didChangeWord:inWord];
	} else {
		static int index = 1;
		NSString *file = [[self temporaryDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"Pasted Image %i.tif", index++]];
		[[inImage TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:1.0] writeToFile:file atomically:YES];
		[self setImageFile:file ofWord:inWord];
	}
}

-(NSImage *)imageForMedia:(NSString *)inMedia
{
	NSString *file = [self pathForMediaFile:inMedia];
	return [[[NSImage alloc] initWithContentsOfFile:file] autorelease];
}

-(NSImage *)imageOfWord:(ProVocWord *)inWord
{
	return [self imageForMedia:[inWord imageMedia]];
}

@end

@implementation ProVocDocument (Movie)

-(NSString *)newMovieFileName
{
	return [NSString newMediaFileName:@"Movie"];
}

-(void)setMovieFile:(NSString *)inFileName ofWord:(ProVocWord *)inWord
{
	NSString *directory = [self temporaryDirectory];
	NSString *mediaName = [[self newMovieFileName] stringByAppendingPathExtension:[inFileName pathExtension]];
	NSString *copyPath = [directory stringByAppendingPathComponent:mediaName];
	if (![[NSFileManager defaultManager] copyPath:inFileName toPath:copyPath handler:nil])
		[NSException raise:@"ProVocInspectorException" format:@"Could not copy movie file %@ to %@", inFileName, copyPath];
	[self willChangeWord:inWord];
	[inWord setMovieMedia:[copyPath lastPathComponent]];
	[self visibleWordsDidChange];
	[self selectedWordParameterDidChange:inWord];
	[self didChangeWord:inWord];
}

-(id)movieForMedia:(NSString *)inMedia
{
	if ([NSApp hasQTKit]) {
		NSString *file = [self pathForMediaFile:inMedia];
		return [QTMovie movieWithFile:file error:nil];
	} else
		return nil;
}

-(id)movieOfWord:(ProVocWord *)inWord
{
	return [self movieForMedia:[inWord movieMedia]];
}

@end

@implementation ProVocDocument (Audio)

-(NSString *)newAudioFileName
{
	return [NSString newMediaFileName:@"Audio"];
}

-(void)setAudioFile:(NSString *)inFileName forKey:(NSString *)inKey ofWord:(ProVocWord *)inWord
{
	NSString *directory = [self temporaryDirectory];
	NSString *mediaName = [[self newAudioFileName] stringByAppendingPathExtension:[inFileName pathExtension]];
	NSString *copyPath = [directory stringByAppendingPathComponent:mediaName];
	if (![[NSFileManager defaultManager] copyPath:inFileName toPath:copyPath handler:nil])
		[NSException raise:@"ProVocInspectorException" format:@"Could not copy audio file %@ to %@", inFileName, copyPath];
	[self willChangeWord:inWord];
	[inWord setMedia:[copyPath lastPathComponent] forAudio:inKey];
	[self visibleWordsDidChange];
	[self selectedWordParameterDidChange:inWord];
	[self didChangeWord:inWord];
}

-(void)playAudio:(NSString *)inKey ofWord:(ProVocWord *)inWord
{
	NSString *file = [self pathForMediaFile:[inWord mediaForAudio:inKey]];
	if (file)
		[[ProVocInspector sharedInspector] playSoundFile:file forAudio:inKey ofWord:inWord];
}

-(BOOL)isPlayingAudio:(NSString *)inKey ofWord:(ProVocWord *)inWord
{
	return [[ProVocInspector sharedInspector] isPlayingAudio:inKey ofWord:inWord];
}

-(NSSound *)audio:(NSString *)inKey ofWord:(ProVocWord *)inWord
{
	return [self audioForMedia:[inWord mediaForAudio:inKey]];
}

-(NSSound *)audioForMedia:(NSString *)inMedia
{
	NSString *file = [self pathForMediaFile:inMedia];
	return [[[NSSound alloc] initWithContentsOfFile:file byReference:YES] autorelease];
}

@end

@implementation ProVocWord (Media)

-(NSMutableDictionary *)mediaDictionary
{
	if (!mMedia)
		mMedia = [[NSMutableDictionary alloc] initWithCapacity:0];
	return mMedia;
}

-(void)reimportMediaFrom:(NSDictionary *)inSource
{
	NSString *temporaryDirectory = [inSource[@"Document"] temporaryDirectory];
	NSString *path = inSource[@"MediaPath"];
	NSEnumerator *enumerator = [mMedia keyEnumerator];
	NSString *key;
	while (key = [enumerator nextObject]) {
		NSString *media = mMedia[key];
		NSString *newMedia = nil;
		NSString *source;
		source = [path stringByAppendingPathComponent:media];
		if (!source || ![[NSFileManager defaultManager] fileExistsAtPath:source])
			source = [temporaryDirectory stringByAppendingPathComponent:media];
		if ([[NSFileManager defaultManager] fileExistsAtPath:source]) {
			NSString *destination;
			do {
				newMedia = [[[media stringByDeletingPathExtension] stringByAppendingString:[NSString stringWithFormat:@"%02X", rand() % 0x100]] stringByAppendingPathExtension:[media pathExtension]];
				destination = [temporaryDirectory stringByAppendingPathComponent:newMedia];
			} while ([[NSFileManager defaultManager] fileExistsAtPath:destination]);
			if (![[NSFileManager defaultManager] copyPath:source toPath:destination handler:nil])
				newMedia = nil;
		}
		if (newMedia)
			mMedia[key] = newMedia;
		else
			[mMedia removeObjectForKey:key];
	}
}

-(void)swapMedia:(NSString *)inMediaA with:(NSString *)inMediaB
{
	id swap = [mMedia[inMediaA] retain];
	if (mMedia[inMediaB])
		mMedia[inMediaA] = mMedia[inMediaB];
	else
		[mMedia removeObjectForKey:inMediaA];
	if (swap)
		mMedia[inMediaB] = swap;
	else
		[mMedia removeObjectForKey:inMediaB];
	[swap release];
}

-(void)swapSourceAndTargetMedia
{
	[self swapMedia:[self audioMediaKey:@"Source"] with:[self audioMediaKey:@"Target"]];
}

-(NSString *)mediaFileName
{
	NSString *name;
	if ([[self sourceWord] length] == 0) {
		if ([[self targetWord] length] == 0)
			name = NSLocalizedString(@"No Name Media Placeholder", @"");
		else
			name = [self targetWord];
	} else {
		if ([[self targetWord] length] == 0)
			name = [self sourceWord];
		else
			name = [NSString stringWithFormat:@"%@ - %@", [self sourceWord], [self targetWord]];
	}
	return name;
}

@end

@implementation ProVocWord (Movie)

-(NSString *)movieMedia
{
	return [self mediaDictionary][@"Movie"];
}

-(void)setMovieMedia:(NSString *)inName
{
	[self mediaDictionary][@"Movie"] = inName;
}

-(void)exportMovie:(NSDictionary *)inInfo
{
	NSString *media = mMedia[@"Movie"];
	if (media) {
		NSString *destination = [[inInfo[@"Directory"] stringByAppendingPathComponent:[self mediaFileName]] stringByAppendingPathExtension:[media pathExtension]];
		[inInfo[@"Document"] exportMedia:media toFile:destination];
	}
}

-(void)removeMovie
{
	[[self mediaDictionary] removeObjectForKey:@"Movie"];
}

@end

@implementation ProVocWord (Image)

-(NSString *)imageMedia
{
	return [self mediaDictionary][@"Image"];
}

-(void)setImageMedia:(NSString *)inName
{
	[self mediaDictionary][@"Image"] = inName;
}

-(void)exportImage:(NSDictionary *)inInfo
{
	NSString *media = mMedia[@"Image"];
	if (media) {
		NSString *destination = [[inInfo[@"Directory"] stringByAppendingPathComponent:[self mediaFileName]] stringByAppendingPathExtension:[media pathExtension]];
		[inInfo[@"Document"] exportMedia:media toFile:destination];
	}
}

-(void)removeImage
{
	[[self mediaDictionary] removeObjectForKey:@"Image"];
}

@end

@implementation ProVocWord (Audio)

-(NSString *)audioMediaKey:(NSString *)inKey
{
	return [NSString stringWithFormat:@"%@Audio", inKey];
}

-(NSString *)mediaForAudio:(NSString *)inKey
{
	return [self mediaDictionary][[self audioMediaKey:inKey]];
}

-(void)setMedia:(NSString *)inName forAudio:(NSString *)inKey
{
	[self mediaDictionary][[self audioMediaKey:inKey]] = inName;
}

-(BOOL)canPlayAudio:(NSString *)inKey
{
	return [self mediaForAudio:inKey] != nil;
}

-(void)removeAudio:(NSString *)inKey
{
	[[self mediaDictionary] removeObjectForKey:[self audioMediaKey:inKey]];
}

-(void)exportAudio:(NSDictionary *)inInfo
{
	NSString *media = mMedia[[self audioMediaKey:inInfo[@"Key"]]];
	if (media) {
		NSString *name = [self performSelector:NSSelectorFromString(inInfo[@"NameSelectorName"])];
		if ([name length] == 0)
			name = [self performSelector:NSSelectorFromString(inInfo[@"OtherNameSelectorName"])];
		if ([name length] == 0)
			name = NSLocalizedString(@"No Name Media Placeholder", @"");
		NSString *destination = [[inInfo[@"Directory"] stringByAppendingPathComponent:name] stringByAppendingPathExtension:[media pathExtension]];
		[inInfo[@"Document"] exportMedia:media toFile:destination];
	}
}

@end

@implementation ProVocPage (Media)

-(void)reimportMediaFrom:(NSDictionary *)inSource
{
	[mWords makeObjectsPerformSelector:_cmd withObject:inSource];
}

@end

@implementation ProVocChapter (Media)

-(void)reimportMediaFrom:(NSDictionary *)inSource
{
	[mChildren makeObjectsPerformSelector:_cmd withObject:inSource];
}

@end

@implementation ProVocInspectorPanel

@end

@implementation NSString (ProVocInspector)

+(NSString *)newMediaFileName:(NSString *)inKind
{
	int timeStamp = [NSDate timeIntervalSinceReferenceDate];
	int random = rand() % 0x10000;
	return [NSString stringWithFormat:@"%@%X%04X", inKind, timeStamp, random];
}

@end

@implementation ProVocDropView

-(id)initWithFrame:(NSRect)inFrame
{
	if (self = [super initWithFrame:inFrame]) {
		[self registerForDraggedTypes:@[NSFilenamesPboardType]];
	}
	return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

-(NSString *)text
{
	return nil;
}

-(BOOL)isSelected
{
	return [[self window] isKeyWindow] && [[self window] firstResponder] == self;
}

-(NSDictionary *)attributes
{
	static NSDictionary *attributes = nil;
	if (!attributes) {
		NSMutableParagraphStyle *paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
		[paragraphStyle setAlignment:NSCenterTextAlignment];
		NSFont *font = [NSFont fontWithName:@"Lucida Grande" size:18];
		font = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSBoldFontMask];
		attributes = [[NSDictionary alloc] initWithObjectsAndKeys:font, NSFontAttributeName, 
										paragraphStyle, NSParagraphStyleAttributeName,
										[NSColor lightGrayColor], NSForegroundColorAttributeName, nil];
	}
	return attributes;
}

-(void)drawRect:(NSRect)inRect
{
	NSRect r = [self bounds];
	NSString *text = [self text];
	NSAttributedString *string = [[[NSAttributedString alloc] initWithString:text attributes:[self attributes]] autorelease];
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundRectInRect:NSInsetRect([self bounds], 5, 5) radius:5];
	const float pattern[2] = {10.0, 4.0};
	[path setLineDash:pattern count:2 phase:18];
	r = NSInsetRect(r, 10, 10);
	r.size.height = [string heightForWidth:r.size.width];
	r.origin.y = NSMidY([self bounds]) - r.size.height / 2;
	r.size.height += 20;
	r.origin.y -= 20;

	if (mHighlighted) {
		[[NSColor colorWithCalibratedWhite:0.8 alpha:0.5] set];
		[path fill];
	}
	if ([self isSelected]) {
        [NSGraphicsContext saveGraphicsState];
        NSSetFocusRingStyle(NSFocusRingOnly);
		NSBezierPath *path = [NSBezierPath bezierPathWithRoundRectInRect:NSInsetRect([self bounds], 4, 4) radius:7];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
	}
	[[NSColor lightGrayColor] set];
	[path setLineWidth:3];
	[path stroke];
	[string drawInRect:r];
}

-(BOOL)canDropFile:(NSString *)inFileName
{
	return NO;
}

-(NSDragOperation)draggingEntered:(id <NSDraggingInfo>)inSender
{
	NSDragOperation operation = NSDragOperationNone;
	NSArray *files = [[inSender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	if ([files count] == 1) {
		NSEnumerator *enumerator = [files reverseObjectEnumerator];
		NSString *fileName;
		while (fileName = [enumerator nextObject])
			if ([self canDropFile:fileName])
				operation = NSDragOperationCopy;
		mHighlighted = operation == NSDragOperationCopy;
		[self setNeedsDisplay:YES];
	}
	return operation;
}

-(void)draggingExited:(id <NSDraggingInfo>)inSender
{
	mHighlighted = NO;
	[self setNeedsDisplay:YES];
}

-(void)draggingEnded:(id <NSDraggingInfo>)inSender
{
	mHighlighted = NO;
	[self setNeedsDisplay:YES];
}

-(void)concludeDragOperation:(id <NSDraggingInfo>)inSender
{
	mHighlighted = NO;
	[self setNeedsDisplay:YES];
}

-(void)dropFile:(NSString *)inFileName
{
}

-(BOOL)performDragOperation:(id <NSDraggingInfo>)inSender
{
	NSEnumerator *enumerator = [[[inSender draggingPasteboard] propertyListForType:NSFilenamesPboardType] reverseObjectEnumerator];
	NSString *fileName;
	while (fileName = [enumerator nextObject])
		if ([self canDropFile:fileName]) {
			[self dropFile:fileName];
			return YES;
		}
	return NO;
}

-(BOOL)isSelectable
{
	return YES;
}

-(void)awakeFromNib
{
	if ([self isSelectable]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(redisplay:) name:NSWindowDidBecomeKeyNotification object:[self window]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(redisplay:) name:NSWindowDidResignKeyNotification object:[self window]];
	}
}

-(void)redisplay:(id)inSender
{
	[self setNeedsDisplay:YES];
}

-(BOOL)acceptsFirstResponder
{
	return [self isSelectable];
}

-(BOOL)becomeFirstResponder
{
	[self setNeedsDisplay:YES];
	return [self isSelectable];
}

-(BOOL)resignFirstResponder
{
	[self setNeedsDisplay:YES];
	return [self isSelectable];
}

-(BOOL)acceptsFirstMouse:(NSEvent *)inEvent
{
	return [self isSelectable];
}

@end

@implementation ProVocImageDropView

-(NSString *)text
{
	return NSLocalizedString(@"Image Drag Destination Placeholder", @"");
}

-(BOOL)canDropFile:(NSString *)inFileName
{
	return [[NSImage imageUnfilteredFileTypes] containsObject:[inFileName pathExtension]];
}

-(void)dropFile:(NSString *)inFileName
{
	[mInspector setImageFile:inFileName];
}

-(BOOL)validateMenuItem:(NSMenuItem *)inItem
{
	if (([inItem action] == @selector(paste:)) && [NSImage canInitWithPasteboard:[NSPasteboard generalPasteboard]])
		return YES;
	else
		return NO;
}

-(void)paste:(id)inSender
{
	NSImage *image = [[[NSImage alloc] initWithPasteboard:[NSPasteboard generalPasteboard]] autorelease];
	if (image)
		[mInspector setImage:image];
}

@end

@implementation ProVocMovieDropView

-(NSString *)text
{
	return NSLocalizedString(@"Movie Drag Destination Placeholder", @"");
}

-(BOOL)canDropFile:(NSString *)inFileName
{
	return [QTMovie canInitWithFile:inFileName];
}

-(void)dropFile:(NSString *)inFileName
{
	[mInspector setMovieFile:inFileName];
}

-(BOOL)isSelectable
{
	return NO;
}

@end

@implementation NSApplication (QTKit)

-(BOOL)hasQTKit
{
	static BOOL initialized = NO;
	static BOOL hasQTKit;
	if (!initialized) {
		hasQTKit = NSClassFromString(@"QTMovie") != Nil;
		initialized = YES;
	}
	return hasQTKit;
}

@end

@implementation ProVocSoundDropView

-(void)awakeFromNib
{
	[self registerForDraggedTypes:@[NSFilenamesPboardType]];
}

-(BOOL)canDropFile:(NSString *)inFileName
{
	return [[NSSound soundUnfilteredFileTypes] containsObject:[inFileName pathExtension]];
}

-(NSDragOperation)draggingEntered:(id <NSDraggingInfo>)inSender
{
	NSDragOperation operation = NSDragOperationNone;
	NSArray *files = [[inSender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	if ([mInspector canRecordAudio] && [files count] == 1) {
		NSEnumerator *enumerator = [files reverseObjectEnumerator];
		NSString *fileName;
		while (fileName = [enumerator nextObject])
			if ([self canDropFile:fileName])
				operation = NSDragOperationCopy;
	}
	return operation;
}

-(void)dropFile:(NSString *)inFileName
{
	id textField = [self subviewOfClass:[NSTextField class]];
	[mInspector setAudio:[textField tag] == 0 ? @"Source" : @"Target" file:inFileName];
}

-(BOOL)performDragOperation:(id <NSDraggingInfo>)inSender
{
	NSEnumerator *enumerator = [[[inSender draggingPasteboard] propertyListForType:NSFilenamesPboardType] reverseObjectEnumerator];
	NSString *fileName;
	while (fileName = [enumerator nextObject])
		if ([self canDropFile:fileName]) {
			[self dropFile:fileName];
			return YES;
		}
	return NO;
}

@end
//
//  iPodController.m
//  ProVoc
//
//  Created by Simon Bovet on 02.02.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "iPodController.h"
#import "ProVocDocument.h"
#import "ProVocDocument+Lists.h"
#import "ProVocChapter.h"
#import "iPodManager.h"
#import "ProVocPreferences.h"
#import "StringExtensions.h"
#import "ScannerExtensions.h"
#import "ProVocInspector.h"
#import "AppleScriptExtensions.h"

#define QUESTION_FOLDER @"Questions"
#define ANSWER_FOLDER @"__Answers"
#define INDEX_FOLDER @"__Index"
#define INDEX_FILE @"Main.linx"
#define OTHER_INDEX_FILE @"ProVoc.linx"
#define BOTH_INDEX_FILE @"Index.linx"
#define PROVOC_INDEX_FILE [iPodController proVocIndexFile]
#define ROOT @"/ProVoc (Private Data)"
#define WRONG @"__Wrong"
#define FINAL @"__Final"
#define PREFERENCES @"Preferences"
#define NOTES_FOLDER @"Notes"

@interface iPodController (Private)

-(void)setiPodProgress:(float)inProgress;

@end

@interface ProVocDocument (iPodExtern)

-(NSArray *)wordsToBeTestedFrom:(NSArray *)inWords;
-(void)sendPagesToiPod:(id)inSender;
-(BOOL)keepOnSendingToiPod;
-(void)setiPodProgress:(float)inProgress;
-(void)exceptionOccuredWhileSendingToiPod:(NSException *)inException;

@end

@interface ProVocWord (iPodExtern)

-(ProVocWord *)word;

@end

@interface NSString (iPod)

-(BOOL)writeAsiPodNoteToFile:(NSString *)inPath;
-(BOOL)writeAsiPodLinxToFile:(NSString *)inPath;
-(unsigned)lengthAsiPodNote;
-(unsigned)lengthAsiPodLinx;

@end

@interface NSMutableString (iPod)

-(void)removeiPodLinxInvalidCharacters;
-(void)removeiPodNoteInvalidCharacters;

@end

@interface iPodTester (Private)

-(NSString *)diskPath;
-(NSString *)refPath;
-(NSMutableArray *)answers;
-(int)lateComments;
-(BOOL)delayedChoices;
-(int)mediaHideQuestion;

@end


@implementation iPodController

+(void)initialize
{
	[self setKeys:[NSArray arrayWithObject:@"alertTitle"] triggerChangeNotificationsForDependentKey:@"alertMessage"];
}

-(id)initWithDocument:(ProVocDocument *)inDocument
{
	if (self = [super initWithWindowNibName:@"iPodController"]) {
		[self loadWindow];
		mDocument = [inDocument retain];
		mAudioToSendToiPod = [[NSMutableSet alloc] initWithCapacity:0];
	}
	return self;
}

-(void)dealloc
{
	[mDocument release];
	[mException release];
	[mAudioToSendToiPod release];
	[super dealloc];
}

-(BOOL)checkiPod
{
	NSString *version = @"?";
//	BOOL ok = [[self class] getiPodSysInfo:@"buildID" value:nil visible:&version] && [version floatValue] >= 2.0;
	BOOL ok = ![[self class] getiPodSysInfo:@"buildID" value:nil visible:&version] || [version floatValue] >= 2.0; // for iPod nano 2 giga
	if (!ok)
		NSRunAlertPanel(NSLocalizedString(@"Invalid iPod Alert Title", @""),
			[NSString stringWithFormat:NSLocalizedString(@"Invalid iPod Alert Message (%@)", @""), version], nil, nil, nil);
	return ok;
}

-(void)selectTabViewItemAtIndex:(int)inIndex
{
	[mTabView setHidden:YES];
	[mTabView selectTabViewItemAtIndex:inIndex];
	float minY = 1e6;
	float maxY = 0;
	NSEnumerator *enumerator = [[[[mTabView tabViewItemAtIndex:inIndex] view] subviews] objectEnumerator];
	NSView *subview;
	while (subview = [enumerator nextObject]) {
		NSRect frame = [subview frame];
		minY = MIN(minY, NSMinY(frame));
		maxY = MAX(maxY, NSMaxY(frame));
	}
	NSWindow *window = [self window];
	NSRect frame = [window frame];
	float dy = (maxY - minY + 35) - [[window contentView] frame].size.height;
	if ([NSApp systemVersion] >= 0x1040)
		dy *= [window userSpaceScaleFactor];
	frame.size.height += dy;
	frame.origin.y -= dy;
	[window setFrame:frame display:YES animate:[window isVisible]];
	[mTabView setHidden:NO];
}

-(void)send
{
	if (![[iPodManager sharedManager] lockiPod])
		NSRunAlertPanel(NSLocalizedString(@"No iPod Alert Title", @""), NSLocalizedString(@"No iPod Alert Message", @""), nil, nil, nil);
	else if (![self checkiPod])
		[[iPodManager sharedManager] unlockiPod];
	else if ([[mDocument wordsToBeTested] count] == 0) {
		NSRunAlertPanel(NSLocalizedString(@"No Word To Send Alert Title", @""), NSLocalizedString(@"No Word To Send Alert Message", @""), nil, nil, nil);
		[[iPodManager sharedManager] unlockiPod];
	} else {
		[self willChangeValueForKey:@"iconData"];
		[self didChangeValueForKey:@"iconData"];
		mKeepOn = YES;
		[self selectTabViewItemAtIndex:0];
		[NSApp beginSheet:[self window] modalForWindow:[mDocument window] modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
	}
}

-(void)sheetDidEnd:(NSWindow *)inSheet returnCode:(int)inReturnCode contextInfo:(void *)inContextInfo
{
	[inSheet orderOut:nil];
	[self autorelease];
	[[iPodManager sharedManager] unlockiPod];
}

-(IBAction)cancel:(id)inSender
{
	if (mSending)
		mKeepOn = NO;
	else
		[NSApp endSheet:[self window]];
}

-(IBAction)startSending:(id)inSender
{
	mSending = YES;
	[mAudioToSendToiPod removeAllObjects];
	
	[self selectTabViewItemAtIndex:1];
	[NSThread detachNewThreadSelector:@selector(sendPagesToiPod:) toTarget:mDocument withObject:self];
}

-(NSString *)alertTitle
{
	return !mException ? NSLocalizedString(@"iPod Pages Sent with Success Title", @"") : NSLocalizedString(@"iPod Pages Sent Error Title", @"");
}

-(NSString *)alertMessage
{
	return !mException ? NSLocalizedString(@"iPod Pages Sent with Success Message", @"") :
		[NSString stringWithFormat:NSLocalizedString(@"iPod Pages Sent Error Message (%@)", @""), [mException reason]];
}

-(void)handleTransferError:(NSDictionary *)inErrorInfo
{
    NSString *errorMessage = [inErrorInfo objectForKey:NSAppleScriptErrorBriefMessage];
    NSNumber *errorNumber = [inErrorInfo objectForKey:NSAppleScriptErrorNumber];

    NSRunAlertPanel(NSLocalizedString(@"Transfer Error Title", @""), [NSString stringWithFormat:NSLocalizedString(@"Transfer Error Format (%@, %@)", @""), errorNumber, errorMessage], nil, nil, nil);
}

-(void)transferAudioToiPod
{
	if ([mAudioToSendToiPod count] == 0)
		return;
		
	[self setiPodProgress:-1];
	NSAppleEventDescriptor *paths = [[[NSAppleEventDescriptor alloc] initListDescriptor] autorelease];
	NSEnumerator *enumerator = [mAudioToSendToiPod objectEnumerator];
	NSString *audio;
	int index = 1;
	while (audio = [enumerator nextObject]) {
		NSString *path = [mDocument pathForMediaFile:audio]; //[directory stringByAppendingPathComponent:audio];
		[paths insertDescriptor:[NSAppleEventDescriptor descriptorWithString:path] atIndex:index++];
	}

	NSString *scriptPath = [[NSBundle mainBundle] pathForResource:@"iPod" ofType:@"scpt"];
	NSURL *scriptURL = [NSURL fileURLWithPath:scriptPath];

	NSDictionary *errorInfo = nil;
	NSAppleScript *script = [[[NSAppleScript alloc] initWithContentsOfURL:scriptURL error:&errorInfo] autorelease];
	if (!script || errorInfo) {
		[self handleTransferError:errorInfo];
		return;
	}
	NSAppleEventDescriptor *arguments = [[[NSAppleEventDescriptor alloc] initListDescriptor] autorelease];
	[arguments insertDescriptor:paths atIndex:1];
	[arguments insertDescriptor:[NSAppleEventDescriptor descriptorWithString:[mDocument displayName]] atIndex:2];
	NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
	NSString *creator = [NSString stringWithFormat:@"%@ %@", [info objectForKey:@"CFBundleName"], [info objectForKey:@"CFBundleVersion"]];
	[arguments insertDescriptor:[NSAppleEventDescriptor descriptorWithString:creator] atIndex:3];

	errorInfo = nil;
	NSAppleEventDescriptor *result = [script callHandler:@"add_provoc_files" withArguments:arguments errorInfo:&errorInfo];
	if (errorInfo) {
		[self handleTransferError:errorInfo];
		return;
	}

	int scriptResult = [result int32Value];
	if (scriptResult == 1)
		NSRunAlertPanel(NSLocalizedString(@"iPod ProVoc Copy Playlist Title", @""), NSLocalizedString(@"iPod ProVoc Copy Playlist Message", @""), nil, nil, nil);
}

-(void)pagesSentToiPod:(id)inSender
{
	[self transferAudioToiPod];
	mSending = NO;
	
	if (mException) {
		NSRunCriticalAlertPanel([self alertTitle], [self alertMessage], nil, nil, nil);
		mKeepOn = NO;
	}
	
	int numberOfNotes = [[iPodContent currentiPodContent] numberOfNotes];
	if (numberOfNotes > 1000) {
		if (NSRunAlertPanel(NSLocalizedString(@"Too Many iPod Notes Title", @""),
			[NSString stringWithFormat:NSLocalizedString(@"Too Many iPod Notes Message (%i)", @""), numberOfNotes],
			NSLocalizedString(@"Too Many iPod Notes Default Button", @""), 
			NSLocalizedString(@"Too Many iPod Notes Alternate Button", @""), 
			nil) == NSAlertAlternateReturn)
			[[ProVocPreferences sharedPreferences] openiPodView:nil];
		mKeepOn = NO;
	}
	
	if (mKeepOn) {
		[self willChangeValueForKey:@"alertTitle"];
		[self didChangeValueForKey:@"alertTitle"];
		[[iPodManager sharedManager] unlockiPod];
		[self selectTabViewItemAtIndex:2];
	} else
		[self cancel:nil];
}

-(IBAction)confirm:(id)inSender
{
	[NSApp endSheet:[self window]];
}

-(IBAction)eject:(id)inSender{
	[[iPodManager sharedManager] unlockiPod];
	if ([[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath:[[iPodManager sharedManager] iPodPath]])
		[self confirm:inSender];
	else
		NSRunAlertPanel(NSLocalizedString(@"iPod Eject Impossible Title", @""), NSLocalizedString(@"iPod Eject Impossible Message", @""), nil, nil, nil);
}

-(NSImage *)iconImage{
	NSString *path = [[iPodManager sharedManager] iPodPath];
	if (!path)
		return nil;
	NSImage *image = [[[NSImage alloc] initWithSize:NSMakeSize(64, 64)] autorelease];
	[image lockFocus];
	NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
	[icon setScalesWhenResized:YES];
	[icon setSize:NSMakeSize(64, 64)];
	[icon dissolveToPoint:NSZeroPoint fraction:1.0];
	icon = [NSImage imageNamed:@"send"];
	[icon dissolveToPoint:NSMakePoint(0, [image size].height - [icon size].height - 8) fraction:1.0];
	[image unlockFocus];
	return image;
}

-(float)progressValue
{
	return mProgress;
}

-(BOOL)indeterminateProgress
{
	return mProgress < 0;
}

-(BOOL)keepOnSendingToiPod
{
	return mKeepOn;
}

-(void)updateProgress:(id)inSender
{
	[self willChangeValueForKey:@"progressValue"];
	[self willChangeValueForKey:@"indeterminateProgress"];
	mProgress = [inSender floatValue];
	[self didChangeValueForKey:@"progressValue"];
	[self didChangeValueForKey:@"indeterminateProgress"];
	[[self window] display];
}

-(void)setiPodProgress:(float)inProgress
{
	[self performSelectorOnMainThread:@selector(updateProgress:) withObject:[NSNumber numberWithFloat:inProgress] waitUntilDone:YES];
}

-(void)exceptionOccuredWhileSendingToiPod:(NSException *)inException
{
	[mException release];
	mException = [inException retain];
}

@end

@implementation iPodController (iPod)

+(NSString *)iPodNotePath
{
	return [[[iPodManager sharedManager] iPodPath] stringByAppendingPathComponent:NOTES_FOLDER];
}

+(NSString *)proVocIndexFile
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:iPodAllowOtherNotes] ? OTHER_INDEX_FILE : INDEX_FILE;
}

+(BOOL)getiPodSysInfo:(NSString *)inKey value:(long long *)outValue visible:(NSString **)outVisible
{
	BOOL ok = NO;
	long long value = 0;
	NSString *visible = @"";
	NSString *sysInfo = [NSString stringWithContentsOfFile:[[[iPodManager sharedManager] iPodPath] stringByAppendingPathComponent:@"iPod_Control/Device/SysInfo"]];
	if (sysInfo) {
		NSScanner *scanner = [NSScanner scannerWithString:sysInfo];
		NSString *key = [inKey stringByAppendingString:@":"];
		[scanner scanUpToString:key intoString:nil];
		if ([scanner scanString:key intoString:nil]) {
			[scanner scanHexLongLong:&value];
			[scanner scanUpToString:@"(" intoString:nil];
			[scanner scanString:@"(" intoString:nil] && [scanner scanUpToString:@")" intoString:&visible];
			ok = YES;
		}
	}
	if (outValue)
		*outValue = value;
	if (outVisible)
		*outVisible = visible;
	return ok;
}

+(BOOL)isClickWheeliPod
{
	long long revValue;
	return [self getiPodSysInfo:@"boardHwSwInterfaceRev" value:&revValue visible:nil] && revValue >= 0x00040000;
}

+(BOOL)is5GiPod:(float *)outVersion
{
	long long revValue;
	NSString *visibleBuild;
	BOOL ok = [self getiPodSysInfo:@"boardHwSwInterfaceRev" value:&revValue visible:nil] && [self getiPodSysInfo:@"visibleBuildID" value:nil visible:&visibleBuild];
	if (ok && revValue < 0x000B0000)
		ok = NO;
	if (ok && outVersion)
		*outVersion = [visibleBuild floatValue];
	return ok;
}

+(BOOL)updateiPodIndex
{
	NSMutableString *string = [NSMutableString string];
	[string appendString:@"<TITLE>ProVoc</TITLE>"];
	
	BOOL hasContent = NO;
	NSString *dataPath = [[self iPodNotePath] stringByAppendingPathComponent:ROOT];
	NSEnumerator *enumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:dataPath] objectEnumerator];
	NSString *element;
	while (element = [enumerator nextObject])
		if (![element isEqualToString:WRONG] && ![element isEqualToString:FINAL]) {
			[string appendFormat:@"<A HREF=\"%@\">%@</A>", [ROOT stringByAppendingPathComponent:[element stringByAppendingPathComponent:INDEX_FILE]], element];
			hasContent = YES;
		}
		
	[@"<meta name=\"NowPlaying\" content=\"false\">" writeToFile:[[self iPodNotePath] stringByAppendingPathComponent:PREFERENCES] atomically:YES];

	if (hasContent) {
		[[NSFileManager defaultManager] removeFileAtPath:[[self iPodNotePath] stringByAppendingPathComponent:OTHER_INDEX_FILE] handler:nil];
		[[NSFileManager defaultManager] removeFileAtPath:[[self iPodNotePath] stringByAppendingPathComponent:INDEX_FILE] handler:nil];
		return [string writeAsiPodLinxToFile:[[self iPodNotePath] stringByAppendingPathComponent:PROVOC_INDEX_FILE]];
	} else {
		[[NSFileManager defaultManager] removeFileAtPath:[[self iPodNotePath] stringByAppendingPathComponent:PROVOC_INDEX_FILE] handler:nil];
		[[NSFileManager defaultManager] removeFileAtPath:[[self iPodNotePath] stringByAppendingPathComponent:ROOT] handler:nil];
		return YES;
	}
}

+(NSSet *)usedMedia{
	NSMutableSet *usedMedia = [NSMutableSet set];
	NSString *directory = [[self iPodNotePath] stringByAppendingPathComponent:ROOT];
	NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:directory];
	NSString *file;
	NSString *linkHead = @"<A HREF=\"song=";
	NSCharacterSet *linkTail = [NSCharacterSet characterSetWithCharactersInString:@"\"&"];
	BOOL isDir;
	while (file = [enumerator nextObject]) {
		NSString *path = [directory stringByAppendingPathComponent:file];
		if (![[file pathExtension] isEqualToString:@"linx"] && [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && !isDir) {
			NSString *string = [[NSString alloc] initWithContentsOfFile:path];
			if (string) {
				NSScanner *scanner = [[NSScanner alloc] initWithString:string];
				while ([scanner scanUpToString:linkHead intoString:nil]) {
					[scanner scanString:linkHead intoString:nil];
					NSString *media;
					if ([scanner scanUpToCharactersFromSet:linkTail intoString:&media])
						[usedMedia addObject:media];
				}
				[scanner release];
				[string release];
			}
		}
	}
	return usedMedia;
}

-(void)sendAudioToiPod:(NSString *)inAudioPath
{
	[mAudioToSendToiPod addObject:inAudioPath];
}

@end

@implementation ProVocDocument (iPod)

-(NSArray *)pagesToSendToiPod
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:iPodPagesToSend] == 0 ? [self selectedPages] : [self allPages];
}

-(NSString *)iPodPath{
	return [[iPodController iPodNotePath] stringByAppendingPathComponent:ROOT];
}

-(NSString *)iPodTitle{
	return [self displayName];
}

#define IPOD_NOTE_MAX_SIZE 4096

-(BOOL)sendIndexForSortedWords:(NSArray *)inSortedWords inWords:(NSArray *)inWords page:(ProVocPage *)inPage diskRoot:(NSString *)inDiskRoot
	hrefs:(NSArray **)outHRefs linkNames:(NSArray **)outLinkNames
	index:(int)inIndex upToPrefix:(NSString *)inUpToPrefix initialPrefixLength:(int)inInitialPrefixLength remainingWords:(NSArray **)outRemaining
	wordSelector:(SEL)inWordSelector fileNameFormat:(NSString *)inFileNameFormat determinents:(NSArray *)inDeterminents
{
	NSMutableString *mutableName = [NSMutableString string];
	NSMutableString *string = [NSMutableString string];
	int count = 0;
	[string appendFormat:@"<TITLE>%@</TITLE>\n", [[inPage iPodTitle] iPodHTMLString]];
	NSEnumerator *enumerator = [inSortedWords objectEnumerator];
	NSMutableArray *firstNames = [NSMutableArray array];
	NSString *lastName = nil;
	ProVocWord *word;
	while (word = [enumerator nextObject]) {
		unsigned index = [inWords indexOfObjectIdenticalTo:word];
		NSString *originalName = [word performSelector:inWordSelector];
		[mutableName setString:originalName ? originalName : @""];
		[mutableName deleteWords:inDeterminents];
		[mutableName removeAccents];
		NSString *name = [mutableName uppercaseString];
		[firstNames addObject:name];
		if (inUpToPrefix && [name hasPrefix:inUpToPrefix])
			break;
		[string appendFormat:@"<A HREF=\"%i\">%@</A>\n", index, [originalName iPodHTMLString]];
		if ([string lengthAsiPodLinx] > IPOD_NOTE_MAX_SIZE) {
			NSString *commonPrefix = [name commonPrefixWithString:[firstNames objectAtIndex:MAX(0, count - 20)] options:NSCaseInsensitiveSearch];
			if ([commonPrefix length] == [name length])
				[NSException raise:@"iPodController exception" format:@"B1"];
			NSString *upToPrefix = [name substringToIndex:[commonPrefix length] + 1];
			
			NSArray *hRefs;
			NSArray *linkNames;
			NSArray *remainingWords;
			if (![self sendIndexForSortedWords:inSortedWords inWords:inWords page:inPage diskRoot:inDiskRoot
					hrefs:&hRefs linkNames:&linkNames
					index:inIndex upToPrefix:upToPrefix initialPrefixLength:MAX(1, inInitialPrefixLength) remainingWords:&remainingWords
					wordSelector:inWordSelector fileNameFormat:inFileNameFormat determinents:inDeterminents])
				[NSException raise:@"iPodController exception" format:@"B2"];
			NSMutableArray *allHRefs = [[hRefs mutableCopy] autorelease];
			NSMutableArray *allLinkNames = [[linkNames mutableCopy] autorelease];
			if (![self sendIndexForSortedWords:remainingWords inWords:inWords page:inPage diskRoot:inDiskRoot
					hrefs:&hRefs linkNames:&linkNames
					index:inIndex + 1 upToPrefix:nil initialPrefixLength:[upToPrefix length] remainingWords:nil
					wordSelector:inWordSelector fileNameFormat:inFileNameFormat determinents:inDeterminents])
				[NSException raise:@"iPodController exception" format:@"B3"];
			[allHRefs addObjectsFromArray:hRefs];
			[allLinkNames addObjectsFromArray:linkNames];
			if (outHRefs)
				*outHRefs = allHRefs;
			if (outLinkNames)
				*outLinkNames = allLinkNames;
			return YES;
		}
		lastName = name;
		count++;
	}
	if (count < [inSortedWords count] && outRemaining)
		*outRemaining = [inSortedWords subarrayWithRange:NSMakeRange(count, [inSortedWords count] - count)];

	NSString *fileName = [NSString stringWithFormat:inFileNameFormat, inIndex];
	if (outHRefs)
		*outHRefs = [NSArray arrayWithObject:[INDEX_FOLDER stringByAppendingPathComponent:fileName]];
	if (outLinkNames) {
		NSString *linkName;
		if (inInitialPrefixLength == 0)
			linkName = @"";
		else {
			NSString *firstName = [firstNames objectAtIndex:0];
			NSString *firstLetters = [firstName substringToIndex:inInitialPrefixLength];
			NSString *lastLetters = [lastName substringToIndex:MAX(1, [inUpToPrefix length])];
			if ([lastLetters hasPrefix:firstLetters])
				firstLetters = [firstName substringToIndex:MIN([firstName length], [lastLetters length])];
			if ([firstLetters hasPrefix:lastLetters])
				lastLetters = [lastName substringToIndex:MIN([lastName length], [firstLetters length])];
			if ([firstLetters isEqual:lastLetters])
				linkName = [NSString stringWithFormat:@" (%@)", firstLetters];
			else
				linkName = [NSString stringWithFormat:@" (%@ - %@)", firstLetters, lastLetters];
		}
		*outLinkNames = [NSArray arrayWithObject:linkName];
	}
	return [string writeAsiPodLinxToFile:[[inDiskRoot stringByAppendingPathComponent:INDEX_FOLDER] stringByAppendingPathComponent:fileName]];
}

-(BOOL)sendIndexForWords:(NSArray *)inWords sortIdentifier:(NSString *)inSortIdentifier page:(ProVocPage *)inPage diskRoot:(NSString *)inDiskRoot
	hrefs:(NSArray **)outHRefs linkNames:(NSArray **)outLinkNames
{
	SEL wordSelector;
	NSString *fileNameFormat;
	if ([inSortIdentifier isEqual:@"Source"]) {
		wordSelector = @selector(sourceWord);
		fileNameFormat = @"Source%i.linx";
	} else {
		wordSelector = @selector(targetWord);
		fileNameFormat = @"Target%i.linx";
	}
	NSArray *determinents = [self determinentsOfLanguageWithIdentifier:inSortIdentifier ignoreCase:nil ignoreAccents:nil];
	NSMutableArray *sortedWords = [[inWords mutableCopy] autorelease];
	[self sortWords:sortedWords sortIdentifier:inSortIdentifier];

	return [self sendIndexForSortedWords:sortedWords inWords:inWords page:inPage diskRoot:inDiskRoot
				hrefs:outHRefs linkNames:outLinkNames
				index:0 upToPrefix:nil initialPrefixLength:0 remainingWords:nil
				wordSelector:wordSelector fileNameFormat:fileNameFormat determinents:determinents];
}

-(void)sendPage:(ProVocPage *)inPage asIndexesToiPod:(id)inSender deleteContents:(BOOL)inDelete
{
	NSArray *allWords = [self wordsInPages:[NSArray arrayWithObject:inPage]];
	NSArray *words = [self wordsToBeTestedFrom:allWords];

	NSMutableArray *pathComponents = [NSMutableArray array];
	[pathComponents addObject:[self iPodPath]];
	[pathComponents addObject:[self iPodFilename]];
	[pathComponents addObjectsFromArray:[inPage iPodPathComponents]];
	NSString *diskRoot = [NSString pathWithComponents:pathComponents];
	NSString *indexPath = [diskRoot stringByAppendingPathComponent:INDEX_FOLDER];
	
	if (inDelete)
		[[NSFileManager defaultManager] removeFileAtPath:diskRoot handler:nil];
	if (![[NSFileManager defaultManager] createFullDirectoryAtPath:indexPath])
		[NSException raise:@"iPodController exception" format:@"A1"];
		
	NSString *sourceLanguageString = [[self sourceLanguage] iPodHTMLString];
	NSString *targetLanguageString = [[self targetLanguage] iPodHTMLString];
	
	NSEnumerator *enumerator = [words objectEnumerator];
	ProVocWord *word;
	int index = 0;
	NSMutableString *string = [NSMutableString string];
	while (word = [enumerator nextObject]) {
		[string setString:@"<TITLE> </TITLE>\n"];
		NSString *media;
		NSString *text = [[word sourceWord] iPodHTMLString];
		if (media = [word mediaForAudio:@"Source"]) {
			text = [NSString stringWithFormat:@"<A HREF=\"song=%@\">%@</A>", [media stringByDeletingPathExtension], [text length] > 0 ? text : NSLocalizedString(@"iPod Link Audio Listen", @"")];
			[inSender sendAudioToiPod:media];
		}
		[string appendFormat:@"%@:\n%@\n\n", sourceLanguageString, text];
		text = [[word targetWord] iPodHTMLString];
		if (media = [word mediaForAudio:@"Target"]) {
			text = [NSString stringWithFormat:@"<A HREF=\"song=%@\">%@</A>", [media stringByDeletingPathExtension], [text length] > 0 ? text : NSLocalizedString(@"iPod Link Audio Listen", @"")];
			[inSender sendAudioToiPod:media];
		}
		[string appendFormat:@"%@:\n%@\n\n", targetLanguageString, text];
		NSString *comment = [word comment];
		if ([comment length] > 0)
			[string appendFormat:@"(%@)", [comment iPodHTMLString]];
			
		if (![string writeAsiPodNoteToFile:[indexPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%i", index]]])
			[NSException raise:@"iPodController exception" format:@"A2"];

		index++;
	}
	
	NSArray *sourceHRefs;
	NSArray *sourceLinkNames;
	if (![self sendIndexForWords:words sortIdentifier:@"Source" page:inPage diskRoot:diskRoot hrefs:&sourceHRefs linkNames:&sourceLinkNames])
		[NSException raise:@"iPodController exception" format:@"A3"];
	
	NSArray *targetHRefs;
	NSArray *targetLinkNames;
	if (![self sendIndexForWords:words sortIdentifier:@"Target" page:inPage diskRoot:diskRoot hrefs:&targetHRefs linkNames:&targetLinkNames])
		[NSException raise:@"iPodController exception" format:@"A4"];

	[string setString:@""];
	[string appendFormat:@"<TITLE>%@</TITLE>\n", [[inPage iPodTitle] iPodHTMLString]];
	int i, n = [sourceHRefs count];
	for (i = 0; i < n; i++)
		[string appendFormat:@"<A HREF=\"%@\">%@</A>\n", [sourceHRefs objectAtIndex:i], [sourceLanguageString stringByAppendingString:[sourceLinkNames objectAtIndex:i]]];
	n = [targetHRefs count];
	for (i = 0; i < n; i++)
		[string appendFormat:@"<A HREF=\"%@\">%@</A>\n", [targetHRefs objectAtIndex:i], [targetLanguageString stringByAppendingString:[targetLinkNames objectAtIndex:i]]];
	if ([[NSFileManager defaultManager] fileExistsAtPath:[diskRoot stringByAppendingPathComponent:QUESTION_FOLDER]])
		[string appendFormat:@"<A HREF=\"%@\">%@</A>\n", QUESTION_FOLDER, NSLocalizedString(@"iPod Link Questions", @"")];
	if (![string writeAsiPodLinxToFile:[diskRoot stringByAppendingPathComponent:BOTH_INDEX_FILE]])
		[NSException raise:@"iPodController exception" format:@"A5"];
}

-(void)sendPage:(ProVocPage *)inPage toiPod:(id)inSender
{
	BOOL refresh = YES;
	int sendWhat = [[NSUserDefaults standardUserDefaults] integerForKey:iPodContentToSend];
	
	if ((sendWhat & 1) != 0) {
		NSArray *allWords = [self wordsInPages:[NSArray arrayWithObject:inPage]];
		NSArray *words = [self wordsToBeTestedFrom:allWords];
		if ([words count] == 0)
			return;
		
		iPodTester *tester = [[[iPodTester alloc] initWithDocument:self] autorelease];
		[tester setAnswerWords:allWords withParameters:[self parameters]];
		NSMutableArray *pathComponents = [NSMutableArray array];
		[pathComponents addObject:[self iPodFilename]];
		[pathComponents addObjectsFromArray:[inPage iPodPathComponents]];
		[tester sendPage:inPage withWords:words parameters:[self parameters] atPath:[NSString pathWithComponents:pathComponents] relativeTo:[self iPodPath] delegate:inSender];
		refresh = NO;
	}

	if ((sendWhat & 2) != 0) {
		[self sendPage:(ProVocPage *)inPage asIndexesToiPod:inSender deleteContents:refresh];
		return;
	}
}

-(BOOL)deleteObsoleteiPodContentAtPath:(NSString *)inPath chapter:(ProVocChapter *)inChapter
{
	NSMutableArray *names = [NSMutableArray array];
	[names addObject:INDEX_FILE];
	NSEnumerator *enumerator = [[inChapter children] objectEnumerator];
	id child;
	while (child = [enumerator nextObject]) {
		NSString *name = [child iPodFilename];
		NSString *subpath = [inPath stringByAppendingPathComponent:name];
		if ([child isKindOfClass:[ProVocChapter class]]) {
			BOOL isDir;
			if ([[NSFileManager defaultManager] fileExistsAtPath:subpath isDirectory:&isDir])
				if (isDir) {
					if (![self deleteObsoleteiPodContentAtPath:subpath chapter:child])
						return NO;
				} else if (![[NSFileManager defaultManager] removeFileAtPath:subpath handler:nil])
					return NO;
		}

		[names addObject:name];
	}
	
	enumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:inPath] objectEnumerator];
	id element;
	while (element = [enumerator nextObject])
		if (![names containsObject:element]) {
			BOOL really = YES;	// Double check for literal comparison
			NSEnumerator *enumerator = [names objectEnumerator];
			NSString *name;
			while (name = [enumerator nextObject])
				if ([name compare:element] == 0) {
					really = NO;
					break;
				}
			if (really) {
				NSString *subpath = [inPath stringByAppendingPathComponent:element];
				if (![[NSFileManager defaultManager] removeFileAtPath:subpath handler:nil])
					return NO;
			}
		}
		
	return YES;
}

-(BOOL)updateiPodIndexAtPath:(NSString *)inPath chapter:(ProVocChapter *)inChapter
{
	NSMutableString *string = [NSMutableString string];
	NSString *title = [inChapter iPodTitle];
	if (!title)
		title = [self iPodTitle];
	[string appendFormat:@"<TITLE>%@</TITLE>", [title iPodHTMLString]];
	NSEnumerator *enumerator = [[inChapter children] objectEnumerator];
	id child;
	while (child = [enumerator nextObject]) {
		NSString *name = [child iPodFilename];
		NSString *subpath = [inPath stringByAppendingPathComponent:name];
		if ([[NSFileManager defaultManager] fileExistsAtPath:subpath]) {
			if ([child isKindOfClass:[ProVocChapter class]]) {
				if (![self updateiPodIndexAtPath:subpath chapter:child])
					return NO;
				[string appendFormat:@"<A HREF=\"%@/%@\">%@</A>\n", name, INDEX_FILE, [[child iPodTitle] iPodHTMLString]];
			} else
				if ([[NSFileManager defaultManager] fileExistsAtPath:[subpath stringByAppendingPathComponent:BOTH_INDEX_FILE]])
					[string appendFormat:@"<A HREF=\"%@/%@\">%@</A>\n", name, BOTH_INDEX_FILE, [[child iPodTitle] iPodHTMLString]];
				else
					[string appendFormat:@"<A HREF=\"%@/%@\">%@</A>\n", name, QUESTION_FOLDER, [[child iPodTitle] iPodHTMLString]];
		}
	}
	
	if (![[NSFileManager defaultManager] createFullDirectoryAtPath:inPath])
		return NO;
	return [string writeAsiPodLinxToFile:[inPath stringByAppendingPathComponent:INDEX_FILE]];
}

-(void)sendPagesToiPod:(id)inSender
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NS_DURING
		NSString *rootPath = [[self iPodPath] stringByAppendingPathComponent:[self iPodFilename]];
		ProVocChapter *rootChapter = [mProVocData rootChapter];
		if (![self deleteObsoleteiPodContentAtPath:rootPath chapter:rootChapter])
			[NSException raise:@"iPodController exception" format:@"1"];
		
		NSArray *pages = [self pagesToSendToiPod];
		NSEnumerator *enumerator = [pages objectEnumerator];
		ProVocPage *page;
		int count = 0;
		while ((page = [enumerator nextObject]) && [inSender keepOnSendingToiPod]) {
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			[self sendPage:page toiPod:inSender];
			[pool release];
			[inSender setiPodProgress:(float)(++count) / [pages count]];
		}

		if (![self updateiPodIndexAtPath:rootPath chapter:rootChapter])
			[NSException raise:@"iPodController exception" format:@"2"];

		if (![iPodController updateiPodIndex])
			[NSException raise:@"iPodController exception" format:@"3"];
	
	NS_HANDLER
		[inSender performSelectorOnMainThread:@selector(exceptionOccuredWhileSendingToiPod:) withObject:localException waitUntilDone:YES];
	NS_ENDHANDLER
	
	[inSender performSelectorOnMainThread:@selector(pagesSentToiPod:) withObject:nil waitUntilDone:YES];
	[pool release];
}

-(IBAction)sendToiPod:(id)inSender
{
	iPodController *controller = [[iPodController alloc] initWithDocument:self];
	[controller send];
}

-(IBAction)displayiPodPreferences:(id)inSender
{
	[[ProVocPreferences sharedPreferences] openiPodView:nil];
}

-(IBAction)ejectiPod:(id)inSender
{
	if (![[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath:[[iPodManager sharedManager] iPodPath]])
		NSRunAlertPanel(NSLocalizedString(@"iPod Eject Impossible Title", @""), NSLocalizedString(@"iPod Eject Impossible Message", @""), nil, nil, nil);
}

-(void)iPodDidChange:(NSNotification *)inNotification
{
	[self willChangeValueForKey:@"iPodConnected"];
	[self willChangeValueForKey:@"sendToiPodImage"];
	[self didChangeValueForKey:@"iPodConnected"];
	[self didChangeValueForKey:@"sendToiPodImage"];
}

-(BOOL)iPodConnected
{
	return [[iPodManager sharedManager] iPodPath] != nil;;
}

-(NSImage *)sendToiPodImage
{
	NSString *path = [[iPodManager sharedManager] iPodPath];
	if (!path)
		return nil;
	NSSize size = NSMakeSize(38, 32);
	NSImage *image = [[[NSImage alloc] initWithSize:size] autorelease];
	[image lockFocus];
	NSImage *iPod = [[NSWorkspace sharedWorkspace] iconForFile:path];
	[iPod setScalesWhenResized:YES];
	[iPod setSize:NSMakeSize(32, 32)];
	[iPod dissolveToPoint:NSMakePoint(size.width - [iPod size].width, 0) fraction:1.0];
	NSImage *icon = [NSImage imageNamed:@"send"];
	[icon dissolveToPoint:NSMakePoint(0, size.height - [icon size].height - 2) fraction:1.0];
	[image unlockFocus];
	return image;
}

@end

@implementation NSObject (iPod)

-(NSString *)iPodFilename
{
	return [[(ProVocSource *)self iPodTitle] iPodLinkString];
}

@end

@implementation ProVocSource (iPod)

-(NSString *)iPodTitle
{
	return [self title];
}

-(NSArray *)iPodPathComponents
{
	id parent = [self parent];
	if (!parent)
		return [NSArray array];
	else
		return [[parent iPodPathComponents] arrayByAddingObject:[self iPodFilename]];
}

@end

@implementation iPodWord

-(id)initWithIndex:(int)inIndex total:(int)inTotal
{
	if (self = [super init]) {
		mIndex = inIndex;
		mTotal = inTotal;
		int digits = 1 + floor(log10(mTotal + 1));
		NSString *format = [NSString stringWithFormat:@"%%0%ii", digits];
		mTitleFormat = [[NSString alloc] initWithFormat:NSLocalizedString(@"iPod Question %@ of %@", @""), format, format];
	}
	return self;
}

-(void)dealloc
{
	[mTitleFormat release];
	[mQuestion release];
	[mComment release];
	[mAnswers release];
	[mNotes release];
	[mSolution release];
	[mQuestionAudio release];
	[mAnswerAudio release];
	[super dealloc];
}

-(void)setQuestion:(NSString *)inQuestion
{
	if (mQuestion != inQuestion) {
		[mQuestion release];
		mQuestion = [inQuestion retain];
	}
}

-(void)setComment:(NSString *)inComment;
{
	if (mComment != inComment) {
		[mComment release];
		mComment = [inComment retain];
	}
}

-(void)setAnswers:(NSArray *)inAnswers withNotes:(NSArray *)inNotes
{
	if (mAnswers != inAnswers) {
		[mAnswers release];
		mAnswers = [inAnswers retain];
	}
	if (mNotes != inNotes) {
		[mNotes release];
		mNotes = [inNotes retain];
	}
}

-(void)setSolution:(NSString *)inSolution
{
	if (mSolution != inSolution) {
		[mSolution release];
		mSolution = [inSolution retain];
	}
}

-(void)setQuestionAudio:(NSString *)inAudio
{
	if (mQuestionAudio != inAudio) {
		[mQuestionAudio release];
		mQuestionAudio = [inAudio retain];
	}
}

-(void)setAnswerAudio:(NSString *)inAudio
{
	if (mAnswerAudio != inAudio) {
		[mAnswerAudio release];
		mAnswerAudio = [inAudio retain];
	}
}

-(void)setNextWord:(iPodWord *)inWord
{
	mNextWord = inWord;
}

-(NSString *)iPodFilename
{
	return [NSString stringWithFormat:@"%i", mIndex + 1];
}

-(NSString *)iPodTitle
{
	return [NSString stringWithFormat:mTitleFormat, mIndex + 1, mTotal];
}

-(BOOL)sendSolutionToPath:(NSString *)inPath sender:(id)inSender
{
	NSMutableString *string = [NSMutableString string];
	[string appendFormat:@"<TITLE>%@</TITLE>", [mAnswers count] == 1 ? [self iPodTitle] : NSLocalizedString(@"iPod Title Correct", @"")];
	NSString *word = [mQuestion iPodHTMLString];
/*	if (mQuestionAudio) {
		word = [NSString stringWithFormat:@"<A HREF=\"song=%@\">%@</A>", [mQuestionAudio stringByDeletingPathExtension], word];
		[inSender sendAudioToiPod:mQuestionAudio];
	} */
	[string appendFormat:@"%@\n", word];
	if ([inSender lateComments] != 2 && [mComment length] > 0)
		[string appendFormat:@"(%@)\n", [mComment iPodHTMLString]];
	word = [mSolution iPodHTMLString];
	if (mAnswerAudio) {
		word = [NSString stringWithFormat:@"<A HREF=\"song=%@\">%@</A>", [mAnswerAudio stringByDeletingPathExtension], [word length] > 0 ? word : NSLocalizedString(@"iPod Link Audio Listen", @"")];
		[inSender sendAudioToiPod:mAnswerAudio];
	}
	[string appendFormat:@"\n%@\n\n", word];
	NSString *link = mNextWord ? [[inSender refPath] stringByAppendingPathComponent:[QUESTION_FOLDER stringByAppendingPathComponent:[mNextWord iPodFilename]]] : [ROOT stringByAppendingPathComponent:FINAL];
	[string appendFormat:@"<A HREF=\"%@\">%@</A><BR><BR>", link, NSLocalizedString(@"iPod Link Next", @"")];
	return [string writeAsiPodNoteToFile:inPath];
}

-(BOOL)sendNote:(id)inNote toPath:(NSString *)inPath sender:(id)inSender
{
	NSMutableString *string = [NSMutableString string];
	[string appendFormat:@"<TITLE>%@</TITLE>", NSLocalizedString(@"iPod Title Wrong", @"")];
	NSEnumerator *enumerator = [inNote objectEnumerator];
	ProVocWord *word;
	BOOL first = YES;
	while (word = [enumerator nextObject]) {
		if (first)
			first = NO;
		else
			[string appendString:@"\n"];
		[string appendFormat:@"%@\n%@\n", [[word sourceWord] iPodHTMLString], [[word targetWord] iPodHTMLString]];
		if ([inSender lateComments] != 2 && [[word comment] length] > 0)
			[string appendFormat:@"(%@)\n", [[word comment] iPodHTMLString]];
	}
	[string appendFormat:@"\n%@", NSLocalizedString(@"iPod Link Try Again", @"")];
	return [string writeAsiPodNoteToFile:inPath];
}

-(NSString *)pageSeparator
{
	return @"\n\n\n\n\n\n\n\n\n\n\n";
}

-(NSString *)body:(id)inSender
{
	NSMutableString *string = [NSMutableString string];
	if (mQuestionAudio && ([inSender mediaHideQuestion] == 1 || [inSender mediaHideQuestion] == 2)) {
		[string appendFormat:@"<A HREF=\"song=%@\">%@</A>\n", [mQuestionAudio stringByDeletingPathExtension], NSLocalizedString(@"iPod Link Audio Listen", @"")];
		[inSender sendAudioToiPod:mQuestionAudio];
		if ([inSender mediaHideQuestion] == 1)
			[string appendString:[self pageSeparator]];
	}
	if (!mQuestionAudio || [inSender mediaHideQuestion] != 2) {
		NSString *word = [mQuestion iPodHTMLString];
		if (mQuestionAudio && [inSender mediaHideQuestion] != 1 && [inSender mediaHideQuestion] != 2) {
			word = [NSString stringWithFormat:@"<A HREF=\"song=%@\">%@</A>", [mQuestionAudio stringByDeletingPathExtension], [word length] > 0 ? word : NSLocalizedString(@"iPod Link Audio Listen", @"")];
			[inSender sendAudioToiPod:mQuestionAudio];
		}
		[string appendFormat:@"%@\n", word];
	}
	if ([inSender lateComments] == 0 && [mComment length] > 0)
		[string appendFormat:@"(%@)\n", [mComment iPodHTMLString]];
	[string appendString:@"\n"];
	if ([mAnswers count] == 1) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:iPodSinglePageNotes]) {
			[string appendString:[self pageSeparator]];
			NSString *word = [mQuestion iPodHTMLString];
			if (mQuestionAudio) {
				word = [NSString stringWithFormat:@"<A HREF=\"song=%@\">%@</A>", [mQuestionAudio stringByDeletingPathExtension], [word length] > 0 ? word : NSLocalizedString(@"iPod Link Audio Listen", @"")];
				[inSender sendAudioToiPod:mQuestionAudio];
			}
			[string appendFormat:@"%@\n", word];
			if ([inSender lateComments] != 2 && [mComment length] > 0)
				[string appendFormat:@"(%@)\n", [mComment iPodHTMLString]];
			word = [mSolution iPodHTMLString];
			if (mAnswerAudio) {
				word = [NSString stringWithFormat:@"<A HREF=\"song=%@\">%@</A>", [mAnswerAudio stringByDeletingPathExtension], [word length] > 0 ? word : NSLocalizedString(@"iPod Link Audio Listen", @"")];
				[inSender sendAudioToiPod:mAnswerAudio];
			}
			[string appendFormat:@"%@\n\n", word];
			NSString *link = mNextWord ? [mNextWord iPodFilename] : [ROOT stringByAppendingPathComponent:FINAL];
			[string appendFormat:@"<A HREF=\"%@\">%@</A><BR><BR>", link, NSLocalizedString(@"iPod Link Next", @"")];
		} else {
			NSString *answerPath = [ANSWER_FOLDER stringByAppendingPathComponent:[self iPodFilename]];
			[string appendFormat:@"<A HREF=\"%@\" nopush>%@</A><BR><BR>", [[inSender refPath] stringByAppendingPathComponent:answerPath], NSLocalizedString(@"iPod Link Show Answer", @"")];
			if (![self sendSolutionToPath:[[inSender diskPath] stringByAppendingPathComponent:answerPath] sender:inSender])
				[NSException raise:@"iPodController exception" format:@"4"];
		}
	} else {
		if ([inSender delayedChoices])
			[string appendString:@"\n\n\n\n\n\n\n\n\n\n\n"];
		NSEnumerator *answerEnumerator = [mAnswers objectEnumerator];
		NSEnumerator *noteEnumerator = [mNotes objectEnumerator];
		NSString *answer;
		while (answer = [answerEnumerator nextObject]) {
			id note = [noteEnumerator nextObject];
			BOOL solution = answer == mSolution;
			if (solution) {
				if ([inSender lateComments] == 1 && [mComment length] > 0 || mAnswerAudio) {
					NSString *answerPath = [ANSWER_FOLDER stringByAppendingPathComponent:[self iPodFilename]];
					[string appendFormat:@"<A HREF=\"%@\" nopush>%@</A>\n", [[inSender refPath] stringByAppendingPathComponent:answerPath], [answer iPodHTMLString]];
					if (![self sendSolutionToPath:[[inSender diskPath] stringByAppendingPathComponent:answerPath] sender:inSender])
						[NSException raise:@"iPodController exception" format:@"5"];
				} else {
					NSString *link = mNextWord ? [mNextWord iPodFilename] : [ROOT stringByAppendingPathComponent:FINAL];
					[string appendFormat:@"<A HREF=\"%@\">%@</A>\n", link, [answer iPodHTMLString]];
				}
			} else {
				if ([note isKindOfClass:[NSArray class]]) {
					NSMutableArray *answers = [inSender answers];
					unsigned index = [answers indexOfObject:answer];
					BOOL create = index == NSNotFound;
					if (create) {
						index = [answers count];
						[answers addObject:answer];
					}
					NSString *answerPath = [NSString stringWithFormat:@"%@/W_%i", ANSWER_FOLDER, index];
					[string appendFormat:@"<A HREF=\"%@\">%@</A>\n", [[inSender refPath] stringByAppendingPathComponent:answerPath], [answer iPodHTMLString]];
					if (create && ![self sendNote:note toPath:[[inSender diskPath] stringByAppendingPathComponent:answerPath] sender:inSender])
						[NSException raise:@"iPodController exception" format:@"6"];
				} else
					[string appendFormat:@"<A HREF=\"%@\">%@</A>\n", [ROOT stringByAppendingPathComponent:WRONG], [answer iPodHTMLString]];
			}
		}
		[string appendString:@"<BR><BR>"];
	}
	return string;
}

-(NSString *)iPodNoteContents:(id)inSender
{
	return [NSString stringWithFormat:@"<TITLE>%@</TITLE>%@", [self iPodTitle], [self body:inSender]];
}

-(BOOL)send:(id)inSender
{
	return [[self  iPodNoteContents:inSender] writeAsiPodNoteToFile:[[[inSender diskPath] stringByAppendingPathComponent:QUESTION_FOLDER] stringByAppendingPathComponent:[self iPodFilename]]];
}

@end

@implementation iPodTester

-(id)initWithDocument:(ProVocDocument *)inDocument
{
    if (self = [super initWithDocument:inDocument]) {
        mProVocDocument = inDocument;
        mWordsArray = [[NSMutableArray alloc] init];
		mSources = [[NSMutableArray alloc] initWithCapacity:0];
		mTargets = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

-(ProVocMCQView *)MCQView
{
	return (ProVocMCQView *)self;
}

-(void)setDisplayAnswers:(BOOL)inDisplay
{
}

-(id)mediaAnswerFromWord:(ProVocWord *)inWord
{
	return nil;
}

-(void)setNotesForAnswer:(NSString *)inString
{
	if (!mNoteWords)
		mNoteWords = [[NSMutableArray alloc] initWithCapacity:0];
	else
		[mNoteWords removeAllObjects];

	ProVocWord *currentWord = [mCurrentWord word];
	NSEnumerator *enumerator = [mAnswerWords objectEnumerator];
	ProVocWord *word;
	while (word = [[enumerator nextObject] word])
		if (![currentWord isEqual:word]) {
			NSString *answer = mDirection ? [word sourceWord] : [word targetWord];
			if ([inString isEqualToString:answer])
				[mNoteWords addObject:word];
		}
}

-(void)setAnswers:(NSArray *)inAnswers solution:(id)inSolution
{
	NSMutableArray *notes = [[NSMutableArray alloc] initWithCapacity:0];
	NSEnumerator *enumerator = [inAnswers objectEnumerator];
	id answer;
	while (answer = [enumerator nextObject])
		if (answer == inSolution || !mShowBacktranslation)
			[notes addObject:[NSNull null]];
		else {
			[self setNotesForAnswer:answer];
			NSArray *noteWords = [mNoteWords copy];
			[notes addObject:noteWords];
			[noteWords release];
		}

	[mCurrentiPodWord setAnswers:inAnswers withNotes:notes];
	[mCurrentiPodWord setSolution:inSolution];
	[notes release];
}

-(BOOL)applyRandomWord
{
	[self updateDirection];
    if ([mWordsArray count] == 0)
		return NO;
	
	iPodWord *newWord = [[iPodWord alloc] initWithIndex:[miPodWords count] total:mTotal];
	[mCurrentiPodWord setNextWord:newWord];
	mCurrentiPodWord = newWord;
	[miPodWords addObject:mCurrentiPodWord];
	
	[mCurrentWord release];
	mCurrentWord = [self chooseRandomWord];
	[mWordsArray removeObjectIdenticalTo:mCurrentWord];
	
	[mCurrentiPodWord setQuestion:[self question]];
	[mCurrentiPodWord setComment:[self comment]];
	[mCurrentiPodWord release];
	[mCurrentiPodWord setQuestionAudio:[mCurrentWord mediaForAudio:!mDirection ? @"Source" : @"Target"]];
	[mCurrentiPodWord setAnswerAudio:[mCurrentWord mediaForAudio:mDirection ? @"Source" : @"Target"]];
	mCurrentWord = nil;
	
	return YES;
}

-(BOOL)sendWrongPageAtPath:(NSString *)inPath
{
	NSMutableString *string = [NSMutableString string];
	[string appendFormat:@"<TITLE>%@</TITLE>%@", NSLocalizedString(@"iPod Title Wrong", @""), NSLocalizedString(@"iPod Link Try Again", @"")];
	return [string writeAsiPodNoteToFile:inPath];
}

-(BOOL)sendFinalPageAtPath:(NSString *)inPath
{
	NSMutableString *string = [NSMutableString string];
	[string appendFormat:@"<TITLE>%@</TITLE>", NSLocalizedString(@"iPod Title Finished", @"")];
	[string appendFormat:@"<A HREF=\"/%@\" popall>%@</A>", PROVOC_INDEX_FILE, NSLocalizedString(@"iPod Link Resume ProVoc", @"")];
	NSString *finished;
	float version;
	if (![iPodController isClickWheeliPod])
		finished = NSLocalizedString(@"iPod Text Finished (<=3G)", @"");
	else if (![iPodController is5GiPod:&version])
		finished = NSLocalizedString(@"iPod Text Finished (<5G)", @"");
	else if (version < 1.1)
		finished = NSLocalizedString(@"iPod Text Finished (5G 1.0)", @"");
	else
		finished = NSLocalizedString(@"iPod Text Finished (>5G 1.1)", @"");
	[string appendFormat:@"\n\n%@", finished];
	return [string writeAsiPodNoteToFile:inPath];
}

-(void)sendPage:(ProVocPage *)inPage withWords:(NSArray*)inWords parameters:(id)inParameters atPath:(NSString *)inPath relativeTo:(NSString *)inDiskRoot delegate:(id)inDelegate
{
	mController = inDelegate;
	miPodWords = [NSMutableArray array];
	mNumberOfChoices = [[inParameters objectForKey:@"testMCQ"] boolValue] ? [[inParameters objectForKey:@"testMCQNumber"] intValue] : 0;
	mDelayedChoices = [[inParameters objectForKey:@"delayedMCQ"] boolValue];
    mRequestedDirection = [[inParameters objectForKey:@"testDirection"] intValue];
	mDirectionProbability = [[inParameters objectForKey:@"testDirectionProbability"] floatValue];
	mLateComments = [[inParameters objectForKey:@"lateComments"] intValue];
	mShowBacktranslation = [[inParameters objectForKey:@"showBacktranslation"] boolValue];
	mMediaHideQuestion = [[inParameters objectForKey:@"mediaHideQuestion"] intValue];
    mMode = 0;
	[self updateDirection];
	[self setWords:inWords];
	
	mTotal = [mWordsArray count];
	while ([self applyRandomWord] && [inDelegate keepOnSendingToiPod])
		;
	
	mDiskPath = [inDiskRoot stringByAppendingPathComponent:inPath];
	[[NSFileManager defaultManager] removeFileAtPath:mDiskPath handler:nil];
	if (![[NSFileManager defaultManager] createFullDirectoryAtPath:mDiskPath])
		[NSException raise:@"iPodController exception" format:@"7"];
	mRefPath = [ROOT stringByAppendingPathComponent:inPath];
	if (![[NSFileManager defaultManager] createFullDirectoryAtPath:[mDiskPath stringByAppendingPathComponent:QUESTION_FOLDER]])
		[NSException raise:@"iPodController exception" format:@"8"];
	NSString *answerPath = [mDiskPath stringByAppendingPathComponent:ANSWER_FOLDER];
	if (![[NSFileManager defaultManager] createFullDirectoryAtPath:answerPath])
		[NSException raise:@"iPodController exception" format:@"9"];
	if (![self sendWrongPageAtPath:[inDiskRoot stringByAppendingPathComponent:WRONG]])
		[NSException raise:@"iPodController exception" format:@"10"];
	if (![self sendFinalPageAtPath:[inDiskRoot stringByAppendingPathComponent:FINAL]])
		[NSException raise:@"iPodController exception" format:@"11"];
	NSEnumerator *enumerator = [miPodWords objectEnumerator];
	iPodWord *word;
	while ([inDelegate keepOnSendingToiPod] && (word = [enumerator nextObject]))
		if (![word send:self])
			[NSException raise:@"iPodController exception" format:@"12"];
}

-(NSString *)diskPath
{
	return mDiskPath;
}

-(NSString *)refPath
{
	return mRefPath;
}

-(NSMutableArray *)answers
{
	if (!mAnswers)
		mAnswers = [NSMutableArray array];
	return mAnswers;
}

-(int)lateComments
{
	return mLateComments;
}

-(BOOL)delayedChoices
{
	return mDelayedChoices;
}

-(int)mediaHideQuestion
{
	return mMediaHideQuestion;
}

-(void)sendAudioToiPod:(NSString *)inAudioPath
{
	[mController sendAudioToiPod:inAudioPath];
}

@end

@implementation NSFileManager (FullDirectory)

-(BOOL)createFullDirectoryAtPath:(NSString *)inPath
{
	NSString *parentPath = [inPath stringByDeletingLastPathComponent];
	if (![self fileExistsAtPath:parentPath] && ![self createFullDirectoryAtPath:parentPath])
		return NO;
	if (![self fileExistsAtPath:inPath] && ![self createDirectoryAtPath:inPath attributes:nil])
		return NO;
	return YES;
}

@end

@implementation NSString (iPodController)

-(NSString *)iPodLinkString
{
/*	static NSCharacterSet *set = nil;
	if (!set)
		set = [[NSCharacterSet characterSetWithCharactersInString:@"\\/\":<>"] retain];
	if ([self rangeOfCharacterFromSet:set].location == NSNotFound)
		return self; */
	NSMutableString *string = [[self mutableCopy] autorelease];
	[string replaceOccurrencesOfString:@"\\" withString:@"_" options:0 range:NSMakeRange(0, [string length])];
	[string replaceOccurrencesOfString:@"/" withString:@"_" options:0 range:NSMakeRange(0, [string length])];
	[string replaceOccurrencesOfString:@"\"" withString:@"_" options:0 range:NSMakeRange(0, [string length])];
	[string replaceOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [string length])];
	[string replaceOccurrencesOfString:@"<" withString:@"_" options:0 range:NSMakeRange(0, [string length])];
	[string replaceOccurrencesOfString:@">" withString:@"_" options:0 range:NSMakeRange(0, [string length])];
	[string removeiPodLinxInvalidCharacters];
	return string;
}

-(NSString *)iPodHTMLString
{
	static NSCharacterSet *set = nil;
	if (!set)
		set = [[NSCharacterSet characterSetWithCharactersInString:@"<>&"] retain];
	if ([self rangeOfCharacterFromSet:set].location == NSNotFound)
		return self;
	NSMutableString *string = [[self mutableCopy] autorelease];
	[string replaceOccurrencesOfString:@"&" withString:@"&amp;" options:0 range:NSMakeRange(0, [string length])];
	[string replaceOccurrencesOfString:@"<" withString:@"&lt;" options:0 range:NSMakeRange(0, [string length])];
	[string replaceOccurrencesOfString:@">" withString:@"&gt;" options:0 range:NSMakeRange(0, [string length])];
	return string;
}

@end

@implementation iPodContent

+(id)currentiPodContent
{
	return [[[self alloc] initWithPath:nil name:nil] autorelease];
}

-(id)initWithPath:(NSString *)inPath name:(NSString *)inName;
{
	if (self = [super init]) {
		if (inPath)
			mPath = [inPath retain];
		else
			mPath = [[iPodController iPodNotePath] retain];
		if (inName) {
			static NSMutableString *string = nil;
			if (!string)
				string = [[NSMutableString string] retain];
			[string setString:inName];
			[string replaceOccurrencesOfString:@"&lt;" withString:@"<" options:0 range:NSMakeRange(0, [string length])];
			[string replaceOccurrencesOfString:@"&gt;" withString:@">" options:0 range:NSMakeRange(0, [string length])];
			[string replaceOccurrencesOfString:@"&amp;" withString:@"&" options:0 range:NSMakeRange(0, [string length])];
			mName = [string copy];
		}

		mExpandable = !inPath || [[NSFileManager defaultManager] fileExistsAtPath:[inPath stringByAppendingPathComponent:INDEX_FILE]];
		
		if (mExpandable) {
			NSString *indexFile = [mPath stringByAppendingPathComponent:inPath ? INDEX_FILE : PROVOC_INDEX_FILE];
			if ([[NSFileManager defaultManager] fileExistsAtPath:indexFile]) {
				mChildren = [[NSMutableArray alloc] initWithCapacity:0];
				NSScanner *scanner = [NSScanner scannerWithString:[NSString stringWithContentsOfFile:indexFile]];
				NSString *ref;
				NSString *name;
				while ([scanner scanLinkWithRef:&ref name:&name]) {
					NSString *childPath;
					if ([ref hasPrefix:@"/"])
						childPath = [[iPodController iPodNotePath] stringByAppendingPathComponent:ref];
					else
						childPath = [mPath stringByAppendingPathComponent:ref];
					NSString *lastPathComponent = [childPath lastPathComponent];
					if ([lastPathComponent isEqualToString:INDEX_FILE] || [lastPathComponent isEqualToString:OTHER_INDEX_FILE] ||
							[lastPathComponent isEqualToString:BOTH_INDEX_FILE] || [lastPathComponent isEqualToString:QUESTION_FOLDER])
						childPath = [childPath stringByDeletingLastPathComponent];
					if ([[NSFileManager defaultManager] fileExistsAtPath:childPath] && ![[childPath lastPathComponent] hasPrefix:@"."]) {
						id child = [[[self class] alloc] initWithPath:childPath name:name];
						[mChildren addObject:child];
						mNumberOfWords += [child numberOfWords];
						mNumberOfNotes += [child numberOfNotes];
						[child release];
					}
				}
				mNumberOfNotes++;
			}
		} else {
			if ([[NSFileManager defaultManager] fileExistsAtPath:[inPath stringByAppendingPathComponent:QUESTION_FOLDER]]) {
				mNumberOfWords = [[[NSFileManager defaultManager] directoryContentsAtPath:[inPath stringByAppendingPathComponent:QUESTION_FOLDER]] count];
				mNumberOfNotes = mNumberOfWords + [[[NSFileManager defaultManager] directoryContentsAtPath:[inPath stringByAppendingPathComponent:ANSWER_FOLDER]] count];
			}
			if ([[NSFileManager defaultManager] fileExistsAtPath:[inPath stringByAppendingPathComponent:INDEX_FOLDER]]) {
				int words = 0, notes = 0;
				NSEnumerator *enumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:[inPath stringByAppendingPathComponent:INDEX_FOLDER]] objectEnumerator];
				NSString *file;
				while (file = [enumerator nextObject])
					if ([[file pathExtension] isEqualToString:@"linx"])
						notes++;
					else
						words++;
				mNumberOfWords += words;
				mNumberOfNotes += words + notes + 1;
			}
		}
		if (!inPath && mNumberOfNotes > 0)
			mNumberOfNotes += 3;
	}
	return self;
}

-(void)dealloc
{
	[mPath release];
	[mName release];
	[mChildren release];
	[super dealloc];
}

-(NSString *)path
{
	return mPath;
}

-(BOOL)isExpandable
{
	return mExpandable;
}

-(int)numberOfWords
{
	return mNumberOfWords;
}

-(int)numberOfNotes
{
	return mNumberOfNotes;
}

-(NSString *)nameWithCountOf:(int)inWhat
{
	return [mName stringByAppendingFormat:NSLocalizedString(@"iPod Page Content Suffix (%i)", @""), inWhat == 0 ? mNumberOfWords : mNumberOfNotes];
}

-(NSArray *)children
{
	return mChildren;
}

@end

@implementation NSScanner (iPod)

-(BOOL)scanTitle:(NSString **)outTitle
{
	if ([self isAtEnd])
		return NO;
	unsigned location = [self scanLocation];
	[self scanUpToString:@"<TITLE>" intoString:nil];
	if (![self scanString:@"<TITLE>" intoString:nil])
		goto error;
	if (![self scanUpToString:@"</TITLE>" intoString:outTitle])
		goto error;
	[self scanString:@"</TITLE>" intoString:nil];
	return YES;
	
error:
	[self setScanLocation:location];
	return NO;
}

-(BOOL)scanLinkWithRef:(NSString **)outRef name:(NSString **)outName
{
	if ([self isAtEnd])
		return NO;
	unsigned location = [self scanLocation];
	[self scanUpToString:@"<A HREF=\"" intoString:nil];
	if (![self scanString:@"<A HREF=\"" intoString:nil])
		goto error;
	if (![self scanUpToString:@"\">" intoString:outRef])
		goto error;
	if (![self scanString:@"\">" intoString:nil])
		goto error;
	if (![self scanUpToString:@"</A>" intoString:outName])
		goto error;
	[self scanString:@"</A>" intoString:nil];
	return YES;
	
error:
	[self setScanLocation:location];
	return NO;
}

@end


@implementation NSString (iPod)

-(NSData *)iPodNoteData:(BOOL)inLinx
{
	NSMutableString *string = [self mutableCopy];
	if (inLinx)
		[string removeiPodLinxInvalidCharacters];
	else
		[string removeiPodNoteInvalidCharacters];
	NSStringEncoding encoding = NSMacOSRomanStringEncoding;
	NSString *encodingName = @"Mac";
	if (![string canBeConvertedToEncoding:encoding]) {
		encoding = NSUnicodeStringEncoding;
		encodingName = @"UTF16";
	}
	NSString *finalString = [[NSString alloc] initWithFormat:@"<?xml encoding=\"%@\"?>\n%@", encodingName, string];
	[string release];
	NSData *data = [finalString dataUsingEncoding:encoding];
	[finalString release];
	return data;
}

-(BOOL)writeAsiPodNoteToFile:(NSString *)inPath linx:(BOOL)inLinx
{
	return [[self iPodNoteData:inLinx] writeToFile:inPath atomically:YES];
}

-(BOOL)writeAsiPodNoteToFile:(NSString *)inPath
{
	return [self writeAsiPodNoteToFile:inPath linx:NO];
}

-(BOOL)writeAsiPodLinxToFile:(NSString *)inPath
{
	return [self writeAsiPodNoteToFile:inPath linx:YES];
}

-(unsigned)lengthAsiPodNote
{
	return [[self iPodNoteData:NO] length];
}

-(unsigned)lengthAsiPodLinx
{
	return [[self iPodNoteData:YES] length];
}

@end

@implementation NSMutableString (iPod)

-(void)removeiPodLinxInvalidCharacters
{
	static NSCharacterSet *invalidCharacters = nil;
	static NSDictionary *validDictionary = nil;
	if (!validDictionary) {
		NSMutableString *stringOfInvalidCharacters = [NSMutableString string];
		NSString *path = [[NSBundle mainBundle] pathForResource:@"iPodLinxCharacters" ofType:@"xml" inDirectory:@""];
		NSDictionary *invalidDictionary = [[NSDictionary alloc] initWithContentsOfFile:path];
		NSMutableDictionary *map = [NSMutableDictionary dictionary];
		NSEnumerator *enumerator = [invalidDictionary keyEnumerator];
		NSString *key;
		while (key = [enumerator nextObject]) {
			NSString *invalid = [invalidDictionary objectForKey:key];
			[stringOfInvalidCharacters appendString:invalid];
			int i;
			for (i = 0; i < [invalid length]; i++)
				[map setObject:key forKey:[NSNumber numberWithUnsignedShort:[invalid characterAtIndex:i]]];
		}
		validDictionary = [map copy];
		invalidCharacters = [[NSCharacterSet characterSetWithCharactersInString:stringOfInvalidCharacters] retain];
	}
	
	int i;
	unichar c;
	for (i = 0; i < [self length]; i++)
		if ([invalidCharacters characterIsMember:c = [self characterAtIndex:i]]) {
			NSNumber *inval = [[NSNumber alloc] initWithUnsignedShort:c];
			NSString *valid = [validDictionary objectForKey:inval];
			[inval release];
			if (valid)
				[self replaceCharactersInRange:NSMakeRange(i, 1) withString:valid];
		}
}

-(void)removeiPodNoteInvalidCharacters
{
	static NSCharacterSet *invalidCharacters = nil;
	static NSDictionary *validDictionary = nil;
	if (!validDictionary) {
		NSMutableString *stringOfInvalidCharacters = [NSMutableString string];
		NSString *path = [[NSBundle mainBundle] pathForResource:@"iPodNoteCharacters" ofType:@"xml" inDirectory:@""];
		NSDictionary *invalidDictionary = [[NSDictionary alloc] initWithContentsOfFile:path];
		NSMutableDictionary *map = [NSMutableDictionary dictionary];
		NSEnumerator *enumerator = [invalidDictionary keyEnumerator];
		NSString *key;
		while (key = [enumerator nextObject]) {
			NSString *invalid = [invalidDictionary objectForKey:key];
			[stringOfInvalidCharacters appendString:invalid];
			int i;
			for (i = 0; i < [invalid length]; i++)
				[map setObject:key forKey:[NSNumber numberWithUnsignedShort:[invalid characterAtIndex:i]]];
		}
		validDictionary = [map copy];
		invalidCharacters = [[NSCharacterSet characterSetWithCharactersInString:stringOfInvalidCharacters] retain];
	}
	
	int i;
	unichar c;
	for (i = 0; i < [self length]; i++)
		if ([invalidCharacters characterIsMember:c = [self characterAtIndex:i]]) {
			NSNumber *inval = [[NSNumber alloc] initWithUnsignedShort:c];
			NSString *valid = [validDictionary objectForKey:inval];
			[inval release];
			if (valid)
				[self replaceCharactersInRange:NSMakeRange(i, 1) withString:valid];
		}
}

@end

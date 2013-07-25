//
//  ProVocDocument+Export.m
//  ProVoc
//
//  Created by Simon Bovet on 01.11.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import "ProVocDocument+Export.h"
#import "ProVocDocument+Lists.h"

#import "ProVocPage.h"
#import "ProVocChapter.h"
#import "ProVocData.h"
#import "ProVocPreferences.h"
#import "StringExtensions.h"
#import "ScannerExtensions.h"
#import "ProVocInspector.h"
#import "ProVocSubmitter.h"

@interface ProVocWord (Export)

-(NSString *)tabSeparatedString;
-(void)appendTabSeparatedStringTo:(NSMutableString *)ioString;

@end

@interface ProVocPage (Export)

-(NSString *)tabSeparatedString;
-(void)appendTabSeparatedStringTo:(NSMutableString *)ioString;

@end

@interface ProVocDocument (Extern)

-(void)insertChildren:(NSArray *)inChildren item:(id)inItem atIndex:(int)inIndex;

@end

@implementation ProVocDocument (Export)

-(NSString *)stringFromPages:(NSArray *)inPages
{
	NSMutableString *string = [NSMutableString string];
	[inPages makeObjectsPerformSelector:@selector(appendTabSeparatedStringTo:) withObject:string];
	return string;
}

-(NSString *)stringFromWords:(NSArray *)inWords
{
	NSMutableString *string = [NSMutableString string];
	[inWords makeObjectsPerformSelector:@selector(appendTabSeparatedStringTo:) withObject:string];
	return string;
}

-(NSString *)exportString
{
	NSMutableString *string = [NSMutableString string];
	[[self selectedPages] makeObjectsPerformSelector:@selector(appendExportStringTo:) withObject:string];
	return string;
}
		
-(void)exportPanelDidEnd:(NSSavePanel *)inPanel returnCode:(int)inReturnCode contextInfo:(void *)inContextInfo
{
	if (inReturnCode == NSOKButton) {
		id string = [self exportString];
		if ([self useCustomEncoding]) {
			NSData *data = [string dataUsingEncoding:[self stringEncoding]];
			if (data)
				string = data;
		}
		[string writeToFile:[inPanel filename] atomically:YES];
	}
}

-(IBAction)export:(id)inSender
{
	NSSavePanel *panel = [NSSavePanel savePanel];
	[panel setAccessoryView:mExportAccessoryView];
	[panel setRequiredFileType:@"txt"];
	[panel setCanSelectHiddenExtension:YES];
	[panel beginSheetForDirectory:nil file:nil modalForWindow:mMainWindow modalDelegate:self
		didEndSelector:@selector(exportPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

@end

@implementation ProVocDocument (Import)

-(NSArray *)wordsFromString:(NSString *)inString
{
	NSMutableArray *proVocWords = nil;
	NSScanner *scanner = [NSScanner scannerWithString:inString];
	NSArray *words;
	while ([scanner scanLineOfTabSeparatedWords:&words])
		if ([words count] >= 2) {
			ProVocWord *word = [[ProVocWord alloc] init];
			[word setSourceWord:words[0]];
			[word setTargetWord:words[1]];
			if ([words count] >= 3)
				[word setComment:words[2]];
			
			if (!proVocWords)
				proVocWords = [NSMutableArray array];
			[proVocWords addObject:word];
			[word release];
		}
	return proVocWords;
}

-(NSArray *)pagesFromProVocFile:(NSString *)inFile
{
	NSArray *pages = nil;
	NS_DURING
		NSString *path = [inFile stringByAppendingPathComponent:@"Data"];
		NSData *data = [NSData dataWithContentsOfFile:path];
		if (!data)
			data = [NSData dataWithContentsOfFile:inFile];
		if (data) {
			id provocData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			if ([provocData isKindOfClass:[NSDictionary class]])
				pages = [[provocData[@"Data"] rootChapter] children];
			else
				pages = [provocData allPages];
		}
		
		NSString *mediaPath = [inFile stringByAppendingPathComponent:@"Media"];
		NSMutableArray *words = [NSMutableArray array];
		NSEnumerator *pageEnumerator = [pages objectEnumerator];
		ProVocPage *page;
		while (page = [pageEnumerator nextObject])
			[words addObjectsFromArray:[page words]];
		[words makeObjectsPerformSelector:@selector(resetIndexInFile)];
		if (![mediaPath isEqual:[self mediaPathInBundle]] && mediaPath != [self mediaPathInBundle]) {
			NSDictionary *info = @{@"Document": self, @"MediaPath": mediaPath};
			[words makeObjectsPerformSelector:@selector(reimportMediaFrom:) withObject:info];
		}
	NS_HANDLER
	NS_ENDHANDLER
	return pages;
}

-(NSArray *)proVocPagesWithNames:(NSArray *)inPageNames pages:(NSDictionary *)inPages
{
	NSMutableArray *proVocPages = [NSMutableArray array];
	NSEnumerator *enumerator = [inPageNames objectEnumerator];
	id key;
	while (key = [enumerator nextObject]) {
		ProVocPage *page = [[ProVocPage alloc] init];
		[page setTitle:key];
		[page addWords:inPages[key]];
		[proVocPages addObject:page];
		[page release];
	}
	return proVocPages;
}

-(NSString *)stringWithContentsOfFile:(NSString *)inFilename
{
	if (![self useCustomEncoding])
		return [NSString stringWithContentsOfFile:inFilename];
	else {
		NSData *data = [NSData dataWithContentsOfFile:inFilename];
		return [[[NSString alloc] initWithData:data encoding:[self stringEncoding]] autorelease];
	}
}

-(NSArray *)pagesFromCSVFile:(NSString *)inFileName
{
	NSString *defaultName = [[inFileName lastPathComponent] stringByDeletingPathExtension];
	NSMutableArray *pageNames = [NSMutableArray array];
	NSMutableDictionary *pages = [NSMutableDictionary dictionary];
	
	NSString *string = [self stringWithContentsOfFile:inFileName];
	NSScanner *scanner = [NSScanner scannerWithString:string];

	id currentPage = nil;
	id currentPageName = nil;
	while (![scanner isAtEnd]) {
		NSArray *words;
		if (![scanner scanLineOfCSVWords:&words] || [words count] < 2)
			break;
		
		if (!currentPage)
			currentPageName = defaultName;
		if ([words count] >= 4)
			currentPageName = words[2];
		if (![pageNames containsObject:currentPageName]) {
			[pageNames addObject:currentPageName];
			pages[currentPageName] = [NSMutableArray array];
		}
		currentPage = pages[currentPageName];
		
        ProVocWord *word = [[ProVocWord alloc] init];
        [currentPage addObject:word];
		[word release];
        [word setSourceWord:words[0]];
        [word setTargetWord:words[1]];
		if ([words count] >= 4)
	        [word setComment:words[3]];
		else if ([words count] >= 3)
	        [word setComment:words[2]];
	}
	if (!currentPage)
		return nil;
	return [self proVocPagesWithNames:pageNames pages:pages];
}

-(NSArray *)pagesFromString:(NSString *)inString defaultName:(NSString *)inDefaultName
{
	NSMutableArray *pageNames = [NSMutableArray array];
	NSMutableDictionary *pages = [NSMutableDictionary dictionary];
	
	NSScanner *scanner = [NSScanner scannerWithString:inString];
	
	id currentPage = nil;
	id currentPageName = nil;
	while (![scanner isAtEnd]) {
		BOOL newPage = NO;
		if (!currentPage) {
			currentPageName = inDefaultName;
			newPage = YES;
		}
		while ([scanner scanString:@"#" intoString:nil] || [scanner scanString:@"//" intoString:nil]) {
			if ([scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&currentPageName])
				newPage = YES;
			[scanner scanCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:nil];
		}
		if (newPage) {
			if (![pageNames containsObject:currentPageName]) {
				[pageNames addObject:currentPageName];
				pages[currentPageName] = [NSMutableArray array];
			}
			currentPage = pages[currentPageName];
		}

		NSArray *words;
		if (![scanner scanLineOfTabSeparatedWords:&words])
			break;
		if ([words count] >= 1 && [words[0] length] > 0) {
			ProVocWord *word = [[ProVocWord alloc] init];
	        [currentPage addObject:word];
			[word release];
			[word setSourceWord:words[0]];
			if ([words count] >= 2)
				[word setTargetWord:words[1]];
			if ([words count] >= 3)
				[word setComment:words[2]];
		}
	}
	return [self proVocPagesWithNames:pageNames pages:pages];
}

-(NSArray *)pagesFromTextFile:(NSString *)inFileName
{
	return [self pagesFromString:[self stringWithContentsOfFile:inFileName]
					defaultName:[[inFileName lastPathComponent] stringByDeletingPathExtension]];
}

-(NSArray *)pagesFromFile:(NSString *)inFile
{
	NSArray *pages = nil;
	if ([inFile isKindOfClass:[ProVocText class]])
		if (pages = [self pagesFromString:[(ProVocText *)inFile contents] defaultName:NSLocalizedString(@"Imported Lesson Default Name", @"")])
			return pages;
	if (pages = [self pagesFromProVocFile:inFile])
		return pages;
	if (pages = [self pagesFromCSVFile:inFile])
		return pages;
	if (pages = [self pagesFromTextFile:inFile])
		return pages;
	return nil;
}

-(void)importWordsFromFiles:(NSArray *)inFileNames
{
	[self willChangeData];
	NSEnumerator *enumerator = [inFileNames objectEnumerator];
	NSString *file;
	while (file = [enumerator nextObject]) {
		NSArray *pages = [self pagesFromFile:file];
		if (pages)
			[self insertChildren:pages item:[mProVocData rootChapter] atIndex:[[[mProVocData rootChapter] children] count]];
	}
		
	[self pagesDidChange];
	[self didChangeData];
	[self setMainTab:1];
}

-(void)importPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if (returnCode == NSOKButton)
		[self importWordsFromFiles:[sheet filenames]];
}

-(IBAction)import:(id)inSender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setAccessoryView:mImportAccessoryView];
	[openPanel setAllowsMultipleSelection:YES];
    [openPanel beginSheetForDirectory:NULL file:NULL types:NULL modalForWindow:mMainWindow modalDelegate:self didEndSelector:@selector(importPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

-(void)concludeNewImport
{
	NSArray *sources = [[mProVocData rootChapter] children];
	if ([sources count] <= 1)
		return;
	[[mProVocData rootChapter] removeChild:sources[0]];
	[[NSDocumentController sharedDocumentController] addDocument:self];
	[self makeWindowControllers];
	[self showWindows];
	[[self class] setCurrentDocument:self];
}

@end

@implementation ProVocDocument (Submit)

-(IBAction)submitDocument:(id)inSender
{
	if ([[self allWords] count] == 0) {
		NSRunInformationalAlertPanel(NSLocalizedString(@"No Word To Submit Title", @""), NSLocalizedString(@"No Word To Submit Message", @""), nil, nil, nil);
		return;
	}
	int returnCode = NSAlertOtherReturn;
	if ([self isDocumentEdited])
		returnCode = NSRunInformationalAlertPanel(NSLocalizedString(@"Submit Modified Title", @""), NSLocalizedString(@"Submit Modified Message", @""), NSLocalizedString(@"Submit Save Button", @""), NSLocalizedString(@"Submit Cancel Button", @""), nil);
	else if (![self fileName])
		returnCode = NSRunInformationalAlertPanel(NSLocalizedString(@"Submit Unsaved Title", @""), NSLocalizedString(@"Submit Unsaved Message", @""), NSLocalizedString(@"Submit Save Button", @""), NSLocalizedString(@"Submit Cancel Button", @""), nil);
	else if (![[self fileType] isEqual:@"ProVocDocumentPackage"])
		returnCode = NSRunInformationalAlertPanel(NSLocalizedString(@"Submit Resaved Title", @""), NSLocalizedString(@"Submit Resaved Message", @""), NSLocalizedString(@"Submit Save Button", @""), NSLocalizedString(@"Submit Cancel Button", @""), nil);
	if (returnCode == NSAlertAlternateReturn)
		return;
	if (returnCode == NSAlertDefaultReturn)
		[self saveDocument:nil];
			
	if ([self fileName]) {
		NSEnumerator *enumerator = [[self allWords] objectEnumerator];
		ProVocWord *word;
		int words = 0, audio = 0, images = 0, movies = 0;
		while (word = [enumerator nextObject]) {
			words++;
			if ([word canPlayAudio:@"Source"])
				audio++;
			if ([word canPlayAudio:@"Target"])
				audio++;
			if ([word imageMedia])
				images++;
			if ([word movieMedia])
				movies++;
		}
		ProVocSubmitter *submitter = [[[ProVocSubmitter alloc] init] autorelease];
		[submitter setDelegate:self];
		[submitter submitFile:[self fileName]
			sourceLanguage:[self sourceLanguage]
			targetLanguage:[self targetLanguage]
			info:@{@"Words": @(words),
							@"Audio": @(audio),
							@"Images": @(images),
							@"Movies": @(movies),
							@"Submission Info": mSubmissionInfo}
			modalForWindow:mMainWindow];
	}
}

-(void)submitter:(ProVocSubmitter *)inSubmitter updateSubmissionInfo:(NSDictionary *)inInfo
{
	if (![mSubmissionInfo isEqualToDictionary:inInfo]) {
		[mSubmissionInfo release];
		mSubmissionInfo = [inInfo retain];
		[self saveDocument:nil];
	}
}

@end

@implementation ProVocWord (Export)

-(NSString *)tabSeparatedString
{
	static NSMutableString *string = nil;
	if (!string)
		string = [[NSMutableString alloc] initWithCapacity:0];
	else
		[string setString:@""];
	[self appendTabSeparatedStringTo:string];
	return [[string copy] autorelease];
}

-(void)appendTabSeparatedStringTo:(NSMutableString *)ioString
{
	[ioString appendFormat:[[self comment] length] > 0 ? @"%@\t%@\t%@\n" : @"%@\t%@\n", [self sourceWord], [self targetWord], [self comment]];
}

-(NSString *)escapeQuote:(NSString *)inString
{
	static NSMutableString *string = nil;
	static NSString *backslash;
	static NSString *escapedBackslash;
	static NSString *escapedQuote;
	if (!string) {
		string = [[NSMutableString alloc] initWithCapacity:0];
		backslash = [[NSString alloc] initWithFormat:@"%c", 0x005C];
		escapedBackslash = [[NSString alloc] initWithFormat:@"%c%c", 0x005C, 0x005C];
		escapedQuote = [[NSString alloc] initWithFormat:@"%c\"", 0x005C];
	}
	[string setString:inString ? inString : @""];
	[string replaceOccurrencesOfString:backslash withString:escapedBackslash options:0 range:NSMakeRange(0, [string length])];
	[string replaceOccurrencesOfString:@"\"" withString:escapedQuote options:0 range:NSMakeRange(0, [string length])];
	return [[string copy] autorelease];
}

-(void)appendExportStringTo:(NSMutableString *)ioString
{
	BOOL includeComments = [[NSUserDefaults standardUserDefaults] boolForKey:PVExportComments];
	switch ([[NSUserDefaults standardUserDefaults] integerForKey:PVExportFormat]) {
		case 1: {
			if ([[NSUserDefaults standardUserDefaults] boolForKey:PVExportPageNames])
				[ioString appendFormat:includeComments ? @"\"%@\",\"%@\",\"%@\",\"%@\"\n" : @"\"%@\",\"%@\",\"%@\"\n",
									[self escapeQuote:[self sourceWord]],
									[self escapeQuote:[self targetWord]],
									[self escapeQuote:[[self page] title]],
									[self escapeQuote:[self comment]]];
			else
				[ioString appendFormat:includeComments ? @"\"%@\",\"%@\",\"%@\"\n" : @"\"%@\",\"%@\"\n",
									[self escapeQuote:[self sourceWord]],
									[self escapeQuote:[self targetWord]],
									[self escapeQuote:[self comment]]];
			break;
		}
		default:
			includeComments &= [[self comment] length] > 0;
			[ioString appendFormat:includeComments ? @"%@\t%@\t%@\n" : @"%@\t%@\n", [self sourceWord], [self targetWord], [self comment]];
			break;
	}
}

@end

@implementation ProVocPage (Export)

-(NSString *)tabSeparatedString
{
	static NSMutableString *string = nil;
	if (!string)
		string = [[NSMutableString alloc] initWithCapacity:0];
	else
		[string setString:@""];
	[self appendTabSeparatedStringTo:string];
	return [[string copy] autorelease];
}

-(void)appendTabSeparatedStringTo:(NSMutableString *)ioString
{
	[[self words] makeObjectsPerformSelector:_cmd withObject:ioString];
}

-(void)appendExportStringTo:(NSMutableString *)ioString
{
	BOOL includeTitle = [[NSUserDefaults standardUserDefaults] boolForKey:PVExportPageNames] && [[NSUserDefaults standardUserDefaults] integerForKey:PVExportFormat] == 0;
	if (includeTitle)
		[ioString appendFormat:@"# %@\n", [self title]];
	[[self words] makeObjectsPerformSelector:_cmd withObject:ioString];
	if (includeTitle)
		[ioString appendString:@"\n"];
}

@end

@implementation NSApplication (Import)

-(void)importWordsFromFiles:(NSArray *)inFileNames inNewDocument:(BOOL)inNewDocument
{
	ProVocDocument *document = inNewDocument ? nil : [ProVocDocument currentDocument];
	BOOL newDocument = NO;
	if (!document) {
		document = [[NSDocumentController sharedDocumentController] makeUntitledDocumentOfType:@"ProVocDocumentPackage"];
		newDocument = YES;
	}
	if (document)
		[document importWordsFromFiles:inFileNames];
	if (newDocument)
		[document concludeNewImport];
}

-(IBAction)import:(id)inSender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowsMultipleSelection:YES];
	if ([openPanel runModalForDirectory:nil file:nil types:nil] == NSOKButton)
		[self importWordsFromFiles:[openPanel filenames] inNewDocument:NO];
}

@end

@implementation ProVocText

-(id)initWithContents:(NSString *)inContents
{
	if (self = [super init])
		mContents = [inContents retain];
	return self;
}

-(void)dealloc
{
	[mContents release];
	[super dealloc];
}

-(NSString *)contents
{
	return mContents;
}

@end
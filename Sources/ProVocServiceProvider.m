//
//  ProVocServiceProvider.m
//  ProVoc
//
//  Created by Simon Bovet on 12.05.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ProVocServiceProvider.h"

#import "ProVocDocument.h"
#import "ProVocDocument+Lists.h"
#import "ProVocSilentTester.h"
#import "ProVocPreferences.h"
#import "ProVocApplication.h"
#import "ProVocSpotlighter.h"

@implementation ProVocServiceProvider

-(NSArray *)translationsOfString:(NSString *)inString withDocument:(ProVocDocument *)inDocument
{
	NSMutableArray *translations = [NSMutableArray array];
	ProVocSilentTester *silentTester = [[[ProVocSilentTester alloc] initWithDocument:inDocument] autorelease];
	NSArray *words = [inDocument allWords];
	NSEnumerator *enumerator;
	ProVocWord *word;
	id string;

	[silentTester setLanguage:[inDocument sourceLanguage]];
	string = [silentTester fullGenericAnswerString:inString];
	enumerator = [words objectEnumerator];
	while (word = [enumerator nextObject])
		if ([silentTester isGenericString:string equalToSynonymOfString:[word sourceWord]])
			[translations addObject:[silentTester genericAnswerString:[word targetWord]]];

	[silentTester setLanguage:[inDocument targetLanguage]];
	string = [silentTester fullGenericAnswerString:inString];
	enumerator = [words objectEnumerator];
	while (word = [enumerator nextObject])
		if ([silentTester isGenericString:string equalToSynonymOfString:[word targetWord]])
			[translations addObject:[silentTester genericAnswerString:[word sourceWord]]];
	
	return [translations count] > 0 ? translations : nil;
}

-(id)settingsFrom:(NSDictionary *)inPublicSettings forLanguageName:(NSString *)inName
{
	NSEnumerator *enumerator = [inPublicSettings[@"Languages"] objectEnumerator];
	NSDictionary *description;
	while (description = [enumerator nextObject])
		if ([inName isEqual:description[@"Name"]])
			break;
	return description;
}

-(NSArray *)translationsOfString:(NSString *)inString withDocumentAtPath:(NSString *)inPath
{
	NSData *data = [NSData dataWithContentsOfFile:[inPath stringByAppendingPathComponent:@"Data"]];
	if (!data)
		return nil;
	NSData *publicData = [NSData dataWithContentsOfFile:[inPath stringByAppendingPathComponent:@"PublicSettings"]];
	if (!publicData)
		return nil;
	ProVocData *provocData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	NSDictionary *publicSettings = [NSKeyedUnarchiver unarchiveObjectWithData:publicData];
	
	NSMutableArray *translations = [NSMutableArray array];
	ProVocSilentTester *silentTester = [[[ProVocSilentTester alloc] init] autorelease];
	NSArray *words = [provocData allWords];
	NSEnumerator *enumerator;
	ProVocWord *word;

	[silentTester setLanguageSettings:[self settingsFrom:publicSettings forLanguageName:[provocData sourceLanguage]]];
	enumerator = [words objectEnumerator];
	while (word = [enumerator nextObject])
		if ([silentTester isString:inString equalToSynonymOfString:[word sourceWord]])
			[translations addObject:[silentTester genericAnswerString:[word targetWord]]];

	[silentTester setLanguageSettings:[self settingsFrom:publicSettings forLanguageName:[provocData targetLanguage]]];
	enumerator = [words objectEnumerator];
	while (word = [enumerator nextObject])
		if ([silentTester isString:inString equalToSynonymOfString:[word targetWord]])
			[translations addObject:[silentTester genericAnswerString:[word sourceWord]]];
	
	return [translations count] > 0 ? translations : nil;
}

-(NSArray *)allTranslationsOfString:(NSString *)inString
{
	NSArray *translations;
	if ([ProVocDocument currentDocument])
		if (translations = [self translationsOfString:inString withDocument:[ProVocDocument currentDocument]])
			return translations;
		
	NSMutableArray *documentPaths = [NSMutableArray array];
	NSEnumerator *enumerator = [[[NSDocumentController sharedDocumentController] documents] objectEnumerator];
	id document;
	while (document = [enumerator nextObject]) {
		if ([document fileName])
			[documentPaths addObject:[document fileName]];
		if (document != [ProVocDocument currentDocument] && [document isKindOfClass:[ProVocDocument class]])
			if (translations = [self translationsOfString:inString withDocument:document])
				return translations;
	}
				
	enumerator = [[[NSDocumentController sharedDocumentController] recentDocumentURLs] objectEnumerator];
	NSURL *url;
	while (url = [enumerator nextObject]) {
		NSString *path = [url path];
		if (![documentPaths containsObject:path]) {
			[documentPaths addObject:path];
			if (translations = [self translationsOfString:inString withDocumentAtPath:path])
				return translations;
		}
	}
	
	if ([NSApp systemVersion] >= 0x1040) {
		ProVocSpotlighter *spotlighter = [[[ProVocSpotlighter alloc] init] autorelease];
		NSArray *paths = [spotlighter allProVocFilesContaining:inString];
		NSEnumerator *enumerator = [paths objectEnumerator];
		NSString *path;
		while (path = [enumerator nextObject])
			if (![documentPaths containsObject:path]) {
				[documentPaths addObject:path];
				if (translations = [self translationsOfString:inString withDocumentAtPath:path])
					return translations;
			}
	}
	return nil;
}

-(NSArray *)translationsOfString:(NSString *)inString
{
	NSMutableSet *set = [NSMutableSet set];
	NSEnumerator *enumerator = [[self allTranslationsOfString:inString] objectEnumerator];
	NSString *translation;
	while (translation = [enumerator nextObject])
		[set addObject:translation];
	return [set allObjects];
}

-(NSString *)translate:(NSString *)inString
{
	NSArray *translations = [self translationsOfString:inString];
	if ([translations count] == 0)
		return nil;
	else
		return [translations componentsJoinedByString:[[NSUserDefaults standardUserDefaults] stringForKey:PVPrefSynonymSeparator]];
}

-(void)translate:(NSPasteboard *)inPasteboard userData:(NSString *)inUserData error:(NSString **)outError
{
    NSString *string = [inPasteboard stringForType:NSStringPboardType];
	if (!string)
	    string = [inPasteboard stringForType:NSRTFDPboardType];
	if (!string)
	    string = [inPasteboard stringForType:NSRTFPboardType];
	
    if (!string) {
		*outError = NSLocalizedString(@"Translation Service Invalid Pasteboard Error", @"");
		return;
    }
 
	NSString *newString = [self translate:string];
    if (!newString) {
		*outError = NSLocalizedString(@"Translation Service No Translation Error", @"");
        return;
    }
    [inPasteboard declareTypes:@[NSStringPboardType] owner:nil];
    [inPasteboard setString:newString forType:NSStringPboardType];
}

@end

//
//  ProVocAppleScriptSupport.m
//  ProVoc
//
//  Created by Simon Bovet on 19.05.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ProVocAppleScriptSupport.h"

#import "ProVocDocument+Export.h"
#import "ProVocDocument+Lists.h"

@interface NSScriptCommand (Private)

-(BOOL)boolForArgument:(id)inKey defaultValue:(BOOL)inDefaultValue;

@end

@implementation NSScriptCommand (Private)

-(BOOL)boolForArgument:(id)inKey defaultValue:(BOOL)inDefaultValue
{
	BOOL value = inDefaultValue;
	id arg = [self evaluatedArguments][inKey];
	if ([arg respondsToSelector:@selector(objCType)] && strcmp([arg objCType], @encode(BOOL)) == 0)
		value = [arg boolValue];
	else if ([arg respondsToSelector:@selector(intValue)])
		value = [arg intValue] != 0;
	return value;
}

@end

@implementation ProVocImportFileCommand

-(id)performDefaultImplementation
{
	id args = [self evaluatedArguments];
	NSMutableArray *files = [NSMutableArray array];
	id elements = args[@""];

	if ([elements isKindOfClass:[NSString class]])
		elements = @[elements];
	if ([elements isKindOfClass:[NSArray class]] && [elements count] > 0) {
		NSEnumerator *enumerator = [elements objectEnumerator];
		NSString *path;
		while (path = [enumerator nextObject])
			if ([[NSFileManager defaultManager] fileExistsAtPath:path])
				[files addObject:path];
	}
	
	NSLog(@"importing files (new %i, curr: %p): %@", [self boolForArgument:@"NewDocument" defaultValue:NO], [ProVocDocument currentDocument], files);
	
	if ([files count] > 0)
		[NSApp importWordsFromFiles:files inNewDocument:[self boolForArgument:@"NewDocument" defaultValue:NO]];
	return nil;
}

@end

@implementation ProVocImportTextCommand

-(id)performDefaultImplementation
{
	id args = [self evaluatedArguments];
	ProVocText *text = [[[ProVocText alloc] initWithContents:args[@""]] autorelease];
	[NSApp importWordsFromFiles:@[text] inNewDocument:[self boolForArgument:@"NewDocument" defaultValue:NO]];
	return nil;
}

@end

@implementation ProVocExportFileCommand

-(id)performDefaultImplementation
{
	ProVocDocument *document = [ProVocDocument currentDocument];
	if (!document) {
		NSLog(@"no front doc");
		return @"";
	}
		
	id args = [self evaluatedArguments];
	

	BOOL selectionOnly = [self boolForArgument:@"SelectionOnly" defaultValue:NO];
	BOOL includeNames = [self boolForArgument:@"IncludeNames" defaultValue:NO];
	BOOL includeComments = [self boolForArgument:@"IncludeComments" defaultValue:YES];
	NSArray *pages = selectionOnly ? [document selectedPages] : [document allPages];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	int prevFormat = [defaults integerForKey:PVExportFormat];
	[defaults setInteger:0 forKey:PVExportFormat];
	BOOL prevIncludeComments = [defaults integerForKey:PVExportComments];
	[defaults setBool:includeComments forKey:PVExportComments];
	BOOL prevIncludePageNames = [defaults integerForKey:PVExportPageNames];
	[defaults setBool:includeNames forKey:PVExportPageNames];
	
	NSMutableString *string = [NSMutableString string];
	[pages makeObjectsPerformSelector:@selector(appendExportStringTo:) withObject:string];
			
	[defaults setInteger:prevFormat forKey:PVExportFormat];
	[defaults setBool:prevIncludeComments forKey:PVExportComments];
	[defaults setBool:prevIncludePageNames forKey:PVExportPageNames];

	id thing = string;
	NSString *file = args[@""];
	if ([file isKindOfClass:[NSString class]] && [file length] > 0) {
		if ([document useCustomEncoding]) {
			NSData *data = [string dataUsingEncoding:[document stringEncoding]];
			if (data)
				thing = data;
		}
		[thing writeToFile:file atomically:YES];
	}
	
	NSLog(@"returning %@...", [string substringToIndex:MIN([string length], 10)]);

	return string;	
}

@end


//
//  ScannerExtensions.m
//  ProVoc
//
//  Created by Simon Bovet on 21.04.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import "ScannerExtensions.h"

@implementation NSScanner (ProVocExtensions)

-(BOOL)scanLineOfTabSeparatedWords:(NSArray **)outWords
{
	unsigned location = [self scanLocation];
	NSCharacterSet *skip = [self charactersToBeSkipped];

	NSMutableArray *words = nil;
	[self setCharactersToBeSkipped:[NSCharacterSet spaceCharacterSet]];
	
	NSString *word;
	while (![self isAtEnd]) {
		unsigned lastLocation = [self scanLocation];
		if (![self scanUpToCharactersFromSet:[NSCharacterSet tabAndNewlineCharacterSet] intoString:&word])
			word = @"";
		if (!words)
			words = [NSMutableArray array];
		[words addObject:word];
		if ([self scanCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:nil])
			break;
		[self scanCharacter:nil fromSet:[NSCharacterSet tabCharacterSet]];
		if ([self scanLocation] == lastLocation)
			[self setScanLocation:lastLocation + 1];
	}
	if (!words)
		goto error;
	
	if (outWords)
		*outWords = words;
	[self setCharactersToBeSkipped:skip];
	return YES;
	
error:
	[self setScanLocation:location];
	[self setCharactersToBeSkipped:skip];
	return NO;
}

-(BOOL)scanQuotedWord:(NSString **)outWord
{
	static NSMutableString *string = nil;
	static NSCharacterSet *set;
	static NSString *backslash;
	if (!string) {
		string = [[NSMutableString alloc] initWithCapacity:0];
		backslash = [[NSString alloc] initWithFormat:@"%c", 0x005C];
		set = [[NSCharacterSet characterSetWithCharactersInString:[NSString stringWithFormat:@"\"%@", backslash]] retain];
	} else
		[string setString:@""];
		
	unsigned location = [self scanLocation];
	NSCharacterSet *skip = [self charactersToBeSkipped];

	if (![self scanString:@"\"" intoString:nil])
		goto error;
	[self setCharactersToBeSkipped:[NSCharacterSet emptyCharacterSet]];
	while (![self isAtEnd]) {
		NSString *part = @"";
		[self scanUpToCharactersFromSet:set intoString:&part];
		[string appendString:part];
		if ([self scanString:backslash intoString:nil]) {
			unsigned location = [self scanLocation];
			if (location >= [[self string] length])
				goto error;
			[string appendFormat:@"%C", [[self string] characterAtIndex:location]];
			[self setScanLocation:location + 1];
		} else
			break;
	}
	if (![self scanString:@"\"" intoString:nil])
		goto error;
		
	if (outWord)
		*outWord = [[string copy] autorelease];
	return YES;

error:
	[self setScanLocation:location];
	[self setCharactersToBeSkipped:skip];
	return NO;
}

-(BOOL)scanLineOfCSVWords:(NSArray **)outWords
{
	static NSMutableArray *array = nil;
	if (!array)
		array = [[NSMutableArray alloc] initWithCapacity:0];
	else
		[array removeAllObjects];
		
	unsigned location = [self scanLocation];
	NSCharacterSet *skip = [self charactersToBeSkipped];
	
	NSString *word;
	while (![self isAtEnd]) {
		if (![self scanQuotedWord:&word])
			break;
		[array addObject:word];
		if ([self isAtEnd] || [self scanCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:nil])
			break;
		if (![self scanString:@"," intoString:nil])
			goto error;
	}
	if ([array count] == 0)
		goto error;
		
	if (outWords)
		*outWords = [[array copy] autorelease];
	return YES;
	
error:
	[self setScanLocation:location];
	[self setCharactersToBeSkipped:skip];
	return NO;
}

-(BOOL)scanCharacter:(unichar *)outChar fromSet:(NSCharacterSet *)inCharacterSet
{
	unsigned location = [self scanLocation];
	NSCharacterSet *skip = [self charactersToBeSkipped];

	if ([self isAtEnd])
		goto error;
	
	NSString *string = [self string];
	unichar c = [string characterAtIndex:location];
	if (![inCharacterSet characterIsMember:c])
		goto error;
	
	[self setScanLocation:location + 1];
	if (outChar)
		*outChar = c;
	return YES;
	
error:
	[self setScanLocation:location];
	[self setCharactersToBeSkipped:skip];
	return NO;
}

-(BOOL)scanHexLongLong:(long long *)outValue
{
	unsigned location = [self scanLocation];
	NSCharacterSet *skip = [self charactersToBeSkipped];

	if ([self isAtEnd])
		goto error;
	
	[self setCharactersToBeSkipped:[NSCharacterSet emptyCharacterSet]];
	[self scanCharactersFromSet:skip intoString:nil];
	[self scanString:@"0x" intoString:nil];
	
	static NSCharacterSet *set = nil;
	if (!set)
		set = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEFabcdef"] retain];
	
	BOOL scanned = NO;
	long long value = 0;
	unichar c;
	while ([self scanCharacter:&c fromSet:set]) {
		int digit = c - '0';
		if (digit < 0 || digit >= 10) {
			digit = 10 + c - 'A';
			if (digit < 10 || digit >= 16)
				digit = 10 + c - 'a';
		}
		value = 16 * value + digit;
		scanned = YES;
	}
	
	if (!scanned)
		goto error;
		
	if (outValue)
		*outValue = value;
	return YES;
		
error:	
	[self setScanLocation:location];
	[self setCharactersToBeSkipped:skip];
	return NO;
}

-(id)description
{
	return [NSString stringWithFormat:@"%@ (remaining: '%@')", [super description], [[self string] substringFromIndex:[self scanLocation]]];
}

@end

@implementation NSCharacterSet (ProVocExtensions)

+(NSCharacterSet *)spaceCharacterSet // whitespace - tab
{
	static NSCharacterSet *set = nil;
	if (!set) {
		NSMutableCharacterSet *s = [[self whitespaceCharacterSet] mutableCopy];
		[s formIntersectionWithCharacterSet:[[self tabCharacterSet] invertedSet]];
		set = [s copy];
		[s release];
	}
	return set;
}

+(NSCharacterSet *)newlineCharacterSet
{
	static NSCharacterSet *set = nil;
	if (!set) {
		NSMutableCharacterSet *s = [[self whitespaceAndNewlineCharacterSet] mutableCopy];
		[s formIntersectionWithCharacterSet:[[self whitespaceCharacterSet] invertedSet]];
		set = [s copy];
		[s release];
	}
	return set;
}

+(NSCharacterSet *)tabCharacterSet
{
	static NSCharacterSet *set = nil;
	if (!set)
		set = [[NSCharacterSet characterSetWithCharactersInString:@"\t"] retain];
	return set;
}

+(NSCharacterSet *)tabAndNewlineCharacterSet
{
	static NSCharacterSet *set = nil;
	if (!set) {
		NSMutableCharacterSet *s = [[NSCharacterSet tabCharacterSet] mutableCopy];
		[s formUnionWithCharacterSet:[self newlineCharacterSet]];
		set = [s copy];
		[s release];
	}
	return set;
}

+(NSCharacterSet *)wordSeparatorCharacterSet // tab
{
	static NSCharacterSet *set = nil;
	if (!set)
		set = [[NSCharacterSet characterSetWithCharactersInString:@"\t;"] retain];
	return set;
}

+(NSCharacterSet *)separatorCharacterSet // tab & return
{
	static NSCharacterSet *set = nil;
	if (!set) {
		NSMutableCharacterSet *s = [[self wordSeparatorCharacterSet] mutableCopy];
		[s formUnionWithCharacterSet:[self newlineCharacterSet]];
		set = [s copy];
		[s release];
	}
	return set;
}

+(NSCharacterSet *)emptyCharacterSet
{
	static NSCharacterSet *set = nil;
	if (!set)
		set = [[NSCharacterSet characterSetWithCharactersInString:@""] retain];
	return set;
}

@end


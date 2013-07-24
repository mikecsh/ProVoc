//
//  StringExtensions.m
//  ProVoc
//
//  Created by Simon Bovet on 24.04.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import "StringExtensions.h"


@implementation NSString (StringExtensions)

-(NSString *)stringByRemovingAccents
{
	static NSMutableString *string = nil;
	if (!string)
		string = [[NSMutableString alloc] initWithCapacity:0];
	[string setString:self];
	[string removeAccents];
	return [[string copy] autorelease];
}

-(NSString *)stringByDeletingWords:(NSArray *)inWords
{
	static NSMutableString *string = nil;
	if (!string)
		string = [[NSMutableString alloc] initWithCapacity:0];
	[string setString:self];
	[string deleteWords:inWords];
	return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

-(NSString *)stringByDeletingCharactersInSet:(NSCharacterSet *)inCharacterSet
{
	static NSMutableString *string = nil;
	if (!string)
		string = [[NSMutableString alloc] initWithCapacity:0];
	[string setString:self];
	[string deleteCharactersInSet:inCharacterSet];
	return [[string copy] autorelease];
}

-(float)heightForWidth:(float)inWidth withAttributes:(NSDictionary *)inAttributes
{
	NSAttributedString *string = [[NSAttributedString alloc] initWithString:self attributes:inAttributes];
	float height = [string heightForWidth:inWidth];
	[string release];
	return height;
}

-(NSSize)sizeWithAttributes:(NSDictionary *)inAttributes
{
	NSAttributedString *string = [[NSAttributedString alloc] initWithString:self attributes:inAttributes];
	NSSize size = [string size];
	[string release];
	return size;
}

-(float)widthWithAttributes:(NSDictionary *)inAttributes
{
	NSAttributedString *string = [[NSAttributedString alloc] initWithString:self attributes:inAttributes];
	float width = [string width];
	[string release];
	return width;
}

-(NSString *)nameOfCopyWithExistingNames:(NSArray *)inNames
{
	NSString *copy = [NSString stringWithFormat:NSLocalizedString(@"Copy of %@", @""), self];
	int n = 1;
	while ([inNames containsObject:copy])
		copy = [NSString stringWithFormat:NSLocalizedString(@"Copy of %@ #%i", @""), self, n++];
	return copy;
}

@end

@implementation NSMutableString (StringExtensions)

-(void)removeAccents
{
	static NSCharacterSet *accentedCharacters = nil;
	static NSDictionary *nonAccentedDictionary = nil;
	if (!nonAccentedDictionary) {
		NSMutableString *stringOfAccentedCharacters = [NSMutableString string];
		NSString *path = [[NSBundle mainBundle] pathForResource:@"Accents" ofType:@"xml" inDirectory:@""];
		NSDictionary *accentDictionary = [[NSDictionary alloc] initWithContentsOfFile:path];
		NSMutableDictionary *map = [NSMutableDictionary dictionary];
		NSEnumerator *enumerator = [accentDictionary keyEnumerator];
		NSString *key;
		while (key = [enumerator nextObject]) {
			NSNumber *c = [NSNumber numberWithUnsignedShort:[key characterAtIndex:0]];
			NSString *accents = [accentDictionary objectForKey:key];
			[stringOfAccentedCharacters appendString:accents];
			int i;
			for (i = 0; i < [accents length]; i++)
				[map setObject:c forKey:[NSNumber numberWithUnsignedShort:[accents characterAtIndex:i]]];
		}
		nonAccentedDictionary = [map copy];
		accentedCharacters = [[NSCharacterSet characterSetWithCharactersInString:stringOfAccentedCharacters] retain];
	}
	
	int i;
	unichar c;
	for (i = 0; i < [self length]; i++)
		if ([accentedCharacters characterIsMember:c = [self characterAtIndex:i]]) {
			NSNumber *acc = [[NSNumber alloc] initWithUnsignedShort:c];
			NSNumber *nonAcc = [nonAccentedDictionary objectForKey:acc];
			[acc release];
			if (nonAcc) {
				unichar nonAccChar = [nonAcc unsignedShortValue];
				NSString *repl = [[NSString alloc] initWithCharacters:&nonAccChar length:1];
				[self replaceCharactersInRange:NSMakeRange(i, 1) withString:repl];
				[repl release];
			}
		}
}

-(BOOL)deleteWord:(NSString *)inWord
{
	if ([inWord length] == 0)
		return NO;
	BOOL startsWithSymbol = ![[NSCharacterSet letterCharacterSet] characterIsMember:[inWord characterAtIndex:0]];
	BOOL endsWithSymbol = ![[NSCharacterSet letterCharacterSet] characterIsMember:[inWord characterAtIndex:[inWord length] - 1]];
	BOOL deleted = NO;
	unsigned start = 0;
	NSRange range;
	NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
	while ((range = [self rangeOfString:inWord options:NSCaseInsensitiveSearch range:NSMakeRange(start, [self length] - start)]).location != NSNotFound) {
		unsigned maxRange = NSMaxRange(range);
		if ((range.location == 0 || startsWithSymbol || ![[NSCharacterSet letterCharacterSet] characterIsMember:[self characterAtIndex:range.location - 1]])
				&& (maxRange >= [self length] || endsWithSymbol || ![[NSCharacterSet letterCharacterSet] characterIsMember:[self characterAtIndex:maxRange]])
				&& ([self rangeOfCharacterFromSet:whitespace options:0 range:NSMakeRange(0, range.location)].location != NSNotFound
					|| [self rangeOfCharacterFromSet:whitespace options:0 range:NSMakeRange(maxRange, [self length] - maxRange)].location != NSNotFound)) {
			deleted = YES;
			while (range.location > 0 && [whitespace characterIsMember:[self characterAtIndex:range.location - 1]]) {
				range.location--;
				range.length++;
			}
			while (NSMaxRange(range) < [self length] && [whitespace characterIsMember:[self characterAtIndex:NSMaxRange(range)]])
				range.length++;
			[self deleteCharactersInRange:range];
			start = 0;
		} else
			start = NSMaxRange(range);
	}
	return deleted;
}

-(void)deleteWords:(NSArray *)inWords
{
	BOOL keepOn;
	do {
		keepOn = NO;
		NSEnumerator *enumerator = [inWords objectEnumerator];
		NSString *word;
		while (word = [enumerator nextObject])
			while ([self deleteWord:word])
				keepOn = YES;
	} while (keepOn);
}

-(void)deleteCharactersInSet:(NSCharacterSet *)inCharacterSet
{
	NSRange range;
	while ((range = [self rangeOfCharacterFromSet:inCharacterSet options:NSCaseInsensitiveSearch]).location != NSNotFound)
		[self deleteCharactersInRange:range];
}

-(void)deleteParenthesis
{
	NSRange open;
	while ((open = [self rangeOfString:@"("]).location != NSNotFound) {
		open.length = [self length] - open.location;
		NSRange close = [self rangeOfString:@")" options:0 range:open];
		if (close.location == NSNotFound)
			break;
			
		unsigned last = NSMaxRange(close);
		NSRange range = NSMakeRange(open.location, last - open.location);
		NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
		if ((open.location == 0 || [whitespace characterIsMember:[self characterAtIndex:open.location - 1]])
			&& (last == [self length] || [whitespace characterIsMember:[self characterAtIndex:last]])) {
			while (range.location > 0 && [whitespace characterIsMember:[self characterAtIndex:range.location - 1]]) {
				range.location--;
				range.length++;
			}
			while (NSMaxRange(range) < [self length] && [whitespace characterIsMember:[self characterAtIndex:NSMaxRange(range)]])
				range.length++;
		}
		[self deleteCharactersInRange:range];
	}
}

@end

@implementation NSAttributedString (ProVocExtensions)

-(float)heightForWidth:(float)inWidth
{
	NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:self];
	NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(inWidth, FLT_MAX)];
	NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
	
	[layoutManager addTextContainer:textContainer];
	[textStorage addLayoutManager:layoutManager];
	[textContainer setLineFragmentPadding:0.0];
	
	[layoutManager glyphRangeForTextContainer:textContainer];
	float height = [layoutManager usedRectForTextContainer:textContainer].size.height;
	
	[textStorage release];
	[textContainer release];
	[layoutManager release];
	return height;
}

-(NSSize)size
{
	NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:self];
	NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
	NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
	
	[layoutManager addTextContainer:textContainer];
	[textStorage addLayoutManager:layoutManager];
	[textContainer setLineFragmentPadding:0.0];
	
	[layoutManager glyphRangeForTextContainer:textContainer];
	NSSize size = [layoutManager usedRectForTextContainer:textContainer].size;
	
	[textStorage release];
	[textContainer release];
	[layoutManager release];
	return size;
}

-(float)width
{
	return [self size].width;
}

@end

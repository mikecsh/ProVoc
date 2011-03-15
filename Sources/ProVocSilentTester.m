//
//  ProVocSilentTester.m
//  ProVoc
//
//  Created by Simon Bovet on 02.11.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import "ProVocSilentTester.h"

@interface ProVocTester (Extern)

-(void)setLanguage:(NSString *)inLanguage forDirection:(int)inDirection;
-(void)setLanguageSettings:(NSDictionary *)inSettings forDirection:(int)inDirection;
-(BOOL)isAnswer:(NSString *)inAnswer equalToWord:(NSString *)inWord;

@end

@implementation ProVocSilentTester

-(void)setLanguageSettings:(NSDictionary *)inSettings
{
	mDirection = 0;
	[self setLanguageSettings:inSettings forDirection:mDirection];
}

-(void)setLanguage:(NSString *)inLanguage
{
	mDirection = 0;
	[self setLanguage:inLanguage forDirection:mDirection];
}

-(BOOL)isString:(NSString*)inString equalToString:(NSString*)inOtherString
{
	return [self isAnswer:inString equalToWord:inOtherString];
}

-(BOOL)isString:(NSString*)inString equalToSynonymOfString:(NSString*)inOtherString
{
	id string = [self fullGenericAnswerString:inString];
	
	NSEnumerator *enumerator = [[inOtherString synonyms] objectEnumerator];
	NSString *synonym;
	while (synonym = [enumerator nextObject])
		if ([self isGenericString:string equalToString:synonym])
			return YES;
	return NO;
}

-(BOOL)isGenericString:(NSString*)inString equalToSynonymOfString:(NSString*)inOtherString
{	
	NSEnumerator *enumerator = [[inOtherString synonyms] objectEnumerator];
	NSString *synonym;
	while (synonym = [enumerator nextObject])
		if ([self isGenericString:inString equalToString:synonym])
			return YES;
	return NO;
}

@end

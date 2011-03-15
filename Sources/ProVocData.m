//
//  ProVocData.m
//  ProVoc
//
//  Created by bovet on Sun Feb 09 2003.
//  Copyright (c) 2003 Arizona Software. All rights reserved.
//

#import "ProVocData.h"
#import "ProVocPage.h"
#import "ProVocChapter.h"
#import "ProVocPreferences.h"

@implementation ProVocData

-(id)init
{
    if (self = [super init]) {
		mRootChapter = [[ProVocChapter alloc] init];

		ProVocPage *page = [[ProVocPage alloc] init];
		[page setTitle:[NSString stringWithFormat:NSLocalizedString(@"Page Name %i", ""), 1]];
		[mRootChapter insertChild:page atIndex:0];
		[page release];
		
		NSDictionary *dictionary = [[NSUserDefaults standardUserDefaults] objectForKey:PVPrefsLanguages];
		mSourceLanguage = [[dictionary objectForKey:@"DefaultSource"] retain];
		mTargetLanguage = [[dictionary objectForKey:@"DefaultTarget"] retain];
    }
    return self;
}

-(void)dealloc
{
	[mRootChapter release];
	[mSourceLanguage release];
	[mTargetLanguage release];
    [super dealloc];
}

-(id)initWithCoder:(NSCoder *)inCoder
{
	if (self = [super init]) {
		NSArray *pages = [inCoder allowsKeyedCoding] ? [inCoder decodeObjectForKey:@"ProVocPageArray"] : nil;
        if (pages) {
			mRootChapter = [[ProVocChapter alloc] init];
			[mRootChapter insertChildren:pages atIndex:0];
			mSourceLanguage = [[inCoder decodeObjectForKey:@"ProVocSourceLanguage"] retain];
			mTargetLanguage = [[inCoder decodeObjectForKey:@"ProVocTargetLanguage"] retain];
		} else {
			mRootChapter = [[inCoder decodeObjectForKey:@"RootChapter"] retain];
			mSourceLanguage = [[inCoder decodeObjectForKey:@"SourceLanguage"] retain];
			mTargetLanguage = [[inCoder decodeObjectForKey:@"TargetLanguage"] retain];
		}
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)inCoder
{
	[inCoder encodeObject:mRootChapter forKey:@"RootChapter"];
	[inCoder encodeObject:mSourceLanguage forKey:@"SourceLanguage"];
	[inCoder encodeObject:mTargetLanguage forKey:@"TargetLanguage"];
}

-(ProVocChapter *)rootChapter
{
	return mRootChapter;
}

-(NSArray *)allPages
{
	return [[self rootChapter] allPages];
}

-(NSArray *)allWords
{
	NSMutableArray *array = [NSMutableArray array];
	NSEnumerator *enumerator = [[self allPages] objectEnumerator];
	ProVocPage *page;
	while (page = [enumerator nextObject])
		[array addObjectsFromArray:[page words]];
	return array;
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"%@\n(Root: %@)", [super description], [self rootChapter]];
}

@end

@implementation ProVocData (Language)

-(void)setSourceLanguage:(NSString *)inLanguage
{
	if (mSourceLanguage != inLanguage) {
	    [mSourceLanguage release];
    	mSourceLanguage = [inLanguage retain];
	}
}

-(void)setTargetLanguage:(NSString *)inLanguage
{
	if (mTargetLanguage != inLanguage) {
	    [mTargetLanguage release];
    	mTargetLanguage = [inLanguage retain];
	}
}

-(NSString *)sourceLanguage
{
    return mSourceLanguage;
}

-(NSString *)targetLanguage
{
    return mTargetLanguage;
}

@end

@implementation ProVocSource

-(id)initWithCoder:(NSCoder *)inCoder
{
	if (self = [super init]) {
		mParent = [inCoder decodeObjectForKey:@"Parent"];
		mTitle = [[inCoder decodeObjectForKey:@"Title"] retain];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)inCoder
{
	[inCoder encodeConditionalObject:mParent forKey:@"Parent"];
	[inCoder encodeObject:mTitle forKey:@"Title"];
}

-(void)dealloc
{
	[mTitle release];
	[super dealloc];
}

-(id)parent
{
	return mParent;
}

-(void)setParent:(id)inParent
{
	mParent = inParent;
}

-(void)removeFromParent
{
	[[self parent] removeChild:self];
}

-(NSString *)title
{
	return mTitle;
}

-(void)setTitle:(NSString *)inTitle
{
	if (mTitle != inTitle) {
		[mTitle release];
		mTitle = [inTitle retain];
	}
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"%@ '%@' (0x%x, parent: 0x%x)", NSStringFromClass([self class]), [self title], (int)self, (int)[self parent]];
}

@end

@implementation NSArray (ProVocSource)

-(NSArray *)commonAncestors
{
	NSMutableArray *ancestors = [NSMutableArray array];
	NSEnumerator *enumerator = [self objectEnumerator];
	id source;
	while (source = [enumerator nextObject]) {
		NSEnumerator *ancestorEnumerator = [ancestors objectEnumerator];
		id ancestor;
		while (ancestor = [ancestorEnumerator nextObject])
			if ([ancestor respondsToSelector:@selector(isAncestorOf:)] && [ancestor isAncestorOf:source])
				break;
		if (!ancestor)
			[ancestors addObject:source];
	}
	return ancestors;
}

-(BOOL)containsDescendant:(ProVocSource *)inSource
{
	id parent = inSource;
	while (parent) {
		if ([self containsObject:parent])
			return YES;
		parent = [parent parent];
	}
	return NO;
}

@end

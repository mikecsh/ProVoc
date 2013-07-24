//
//  ProVocChapter.m
//  ProVoc
//
//  Created by Simon Bovet on 31.10.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import "ProVocChapter.h"
#import "ProVocPage.h"

@implementation ProVocChapter

-(id)init
{
	if (self = [super init]) {
		mChildren = [[NSMutableArray alloc] initWithCapacity:0];
	}
	return self;
}

-(void)dealloc
{
	[mChildren release];
	[super dealloc];
}

-(id)initWithCoder:(NSCoder *)inCoder
{
	if (self = [super initWithCoder:inCoder]) {
		mChildren = [[inCoder decodeObjectForKey:@"Children"] retain];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)inCoder
{
	[super encodeWithCoder:inCoder];
	[inCoder encodeObject:mChildren forKey:@"Children"];
}

-(void)addChild:(id)inChild
{
	[self insertChild:inChild atIndex:[[self children] count]];
}

-(void)addChildren:(NSArray *)inChildren
{
	[self insertChildren:inChildren atIndex:[[self children] count]];
}

-(void)insertChild:(id)inChild atIndex:(int)inIndex
{
	[self insertChildren:[NSArray arrayWithObject:inChild] atIndex:inIndex];
}

-(void)insertChildren:(NSArray *)inChildren atIndex:(int)inIndex
{
	NSEnumerator *enumerator = [inChildren reverseObjectEnumerator];
	id child;
	while (child = [enumerator nextObject]) {
		[child setParent:self];
		[mChildren insertObject:child atIndex:inIndex];
	}
}

-(void)removeChild:(id)inChild
{
	[mChildren removeObjectIdenticalTo:inChild];
}

-(NSArray *)children
{
	return mChildren;
}

-(BOOL)isAncestorOf:(id)inChild
{
	NSEnumerator *enumerator = [[self children] objectEnumerator];
	id child;
	while (child = [enumerator nextObject]) {
		if (child == inChild)
			return YES;
		if ([child respondsToSelector:@selector(isAncestorOf:)] && [child isAncestorOf:inChild])
			return YES;
	}
	return NO;
}

-(NSArray *)allPages
{
	NSMutableArray *pages = [NSMutableArray array];
	NSEnumerator *enumerator = [[self children] objectEnumerator];
	id child;
	while (child = [enumerator nextObject])
		if ([child isKindOfClass:[ProVocPage class]])
			[pages addObject:child];
		else
			[pages addObjectsFromArray:[child allPages]];
	return pages;
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"%@\n(Children: %@)", [super description], [self children]];
}

@end

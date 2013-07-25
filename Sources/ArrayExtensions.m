//
//  ArrayExtensions.m
//  ProVoc
//
//  Created by Simon Bovet on 06.10.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import "ArrayExtensions.h"


@implementation NSArray (Shuffle)

-(NSArray *)arrayWithShuffledIndices
{
	NSArray *array = nil;
	static NSMutableArray *indices = nil;
	static NSMutableArray *shuffled = nil;
	if (!indices) {
		indices = [[NSMutableArray array] retain];
		shuffled = [[NSMutableArray array] retain];
	} else {
		[indices removeAllObjects];
		[shuffled removeAllObjects];
	}
	
	unsigned i, n = [self count];
	for (i = 0; i < n; i++) {
		NSNumber *index = [[NSNumber alloc] initWithUnsignedInt:i];
		[indices addObject:index];
		[index release];
	}
	
	while ([indices count] > 0) {
		unsigned index = rand() % [indices count];
		[shuffled addObject:indices[index]];
		[indices removeObjectAtIndex:index];
	}
	
	array = [[shuffled copy] autorelease];
	return array;
}

-(NSArray *)shuffledArray
{
	NSMutableArray *array = [NSMutableArray array];
	NSEnumerator *enumerator = [[self arrayWithShuffledIndices] objectEnumerator];
	id index;
	while (index = [enumerator nextObject])
		[array addObject:self[[index unsignedIntValue]]];
	return array;
}

-(id)randomObject
{
	if ([self count] == 0)
		return nil;
	else
		return self[rand() % [self count]];
}

@end

@implementation NSObject (DeepCopy)

-(id)deepMutableCopy
{
	return [self copy];
}

@end

@implementation NSArray (DeepCopy)

-(id)deepMutableCopy
{
	NSMutableArray *copy = [[NSMutableArray alloc] initWithCapacity:[self count]];
	NSEnumerator *enumerator = [self objectEnumerator];
	id object;
	while (object = [enumerator nextObject]) {
		id objectCopy = [object deepMutableCopy];
		[copy addObject:objectCopy];
		[objectCopy release];
	}
	return copy;
}

@end

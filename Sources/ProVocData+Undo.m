//
//  ProVocData+Undo.m
//  ProVoc
//
//  Created by Simon Bovet on 07.05.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ProVocData+Undo.h"

#import "ProVocChapter.h"
#import "ProVocPage.h"
#import "ArchiverExtensions.h"

@implementation ProVocData (Undo)

-(NSData *)dataForWord:(ProVocWord *)inWord
{
	return [PseudoKeyedArchiver archivedDataWithRootObject:inWord];
}

-(id)identifierForWord:(ProVocWord *)inWord
{
	return [inWord indexIdentifier];
}

-(NSData *)dataForSource:(ProVocSource *)inSource
{
	return [PseudoKeyedArchiver archivedDataWithRootObject:inSource];
}

-(id)identifierForSource:(ProVocSource *)inSource
{
	return [inSource indexIdentifier];
}

-(id)childWithIdentifier:(id)inIdentifier
{
	return [mRootChapter childWithIndexes:inIdentifier];
}

@end

@implementation ProVocSource (Undo)

-(id)indexIdentifier
{
	if (mParent) {
		int index = [[mParent children] indexOfObjectIdenticalTo:self];
		return [[mParent indexIdentifier] arrayByAddingObject:@(index)];
	} else
		return @[];
}

-(NSArray *)indexedChildren
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

-(id)childWithIndexes:(NSArray *)inIndexes
{
	int index = [inIndexes[0] intValue];
	id child = [self indexedChildren][index];
	if ([inIndexes count] == 1)
		return child;
	else
		return [child childWithIndexes:[inIndexes subarrayWithRange:NSMakeRange(1, [inIndexes count] - 1)]];
}

@end

@implementation ProVocChapter (Undo)

-(NSArray *)indexedChildren
{
	return [self children];
}

@end

@implementation ProVocPage (Undo)

-(NSArray *)indexedChildren
{
	return [self words];
}

@end

@implementation ProVocWord (Undo)

-(id)indexIdentifier
{
	int index = [[mPage words] indexOfObjectIdenticalTo:self];
	return [[mPage indexIdentifier] arrayByAddingObject:@(index)];
}

@end
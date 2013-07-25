//
//  ProVocHistory.m
//  ProVoc
//
//  Created by Simon Bovet on 25.02.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ProVocHistory.h"


@implementation ProVocHistory

+(NSColor *)colorForRepetition:(int)inRepetition
{
	switch (inRepetition) {
		case 0:
			return [NSColor greenColor];
		case 1:
			return [NSColor yellowColor];
		case 2:
			return [NSColor orangeColor];
		default:
			return [NSColor redColor];
	}
}

-(id)init
{
	if (self = [super init]) {
		mRepetitions = [[NSMutableArray alloc] initWithCapacity:MAX_HISTORY_REPETITION + 1];
		int i;
		for (i = 0; i <= MAX_HISTORY_REPETITION; i++)
			[mRepetitions addObject:@0];
	}
	return self;
}

-(void)dealloc
{
	[mDate release];
	[mRepetitions release];
	[super dealloc];
}

-(id)initWithCoder:(NSCoder *)inCoder
{
	if (self = [super init]) {
		mDate = [[inCoder decodeObject] retain];
		[inCoder decodeValueOfObjCType:@encode(int) at:&mMode];
		mRepetitions = [[inCoder decodeObject] retain];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)inCoder
{
	[inCoder encodeObject:mDate];
	[inCoder encodeValueOfObjCType:@encode(int) at:&mMode];
	[inCoder encodeObject:mRepetitions];
}

-(void)setDate:(NSDate *)inDate
{
	if (mDate != inDate) {
		[mDate release];
		mDate = [inDate retain];
	}
}

-(void)setMode:(int)inMode
{
	mMode = inMode;
}

-(void)setNumber:(int)inNumber ofRepetition:(int)inRepetition
{
	mRepetitions[inRepetition] = @(inNumber);
}

-(void)addNumber:(int)inNumber ofRepetition:(int)inRepetition
{
	[self setNumber:inNumber + [self numberOfRepetition:inRepetition] ofRepetition:inRepetition];
}

-(void)addHistory:(ProVocHistory *)inHistory
{
	int i;
	for (i = 0; i <= MAX_HISTORY_REPETITION; i++)
		[self addNumber:[inHistory numberOfRepetition:i] ofRepetition:i];
}

-(int)total
{
	int total = 0;
	NSEnumerator *enumerator = [mRepetitions objectEnumerator];
	NSNumber *repetition;
	while (repetition = [enumerator nextObject])
		total += [repetition intValue];
	return total;
}

-(NSDate *)date
{
	return mDate;
}

-(int)numberOfRepetition:(int)inRepetition
{
	return [mRepetitions[inRepetition] intValue];
}

@end

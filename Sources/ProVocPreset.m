//
//  ProVocPreset.m
//  ProVoc
//
//  Created by Simon Bovet on 26.01.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ProVocPreset.h"


@implementation ProVocPreset

-(void)dealloc
{
	[mName release];
	[mParameters release];
	[super dealloc];
}

-(id)copyWithZone:(NSZone *)inZone
{
	ProVocPreset *copy = [[[self class] allocWithZone:inZone] init];
	[copy setName:[self name]];
	[copy setParameters:[self parameters]];
	return copy;
}

-(id)initWithCoder:(NSCoder *)inCoder
{
	if (self = [super init]) {
		mName = [[inCoder decodeObject] retain];
		mParameters = [[inCoder decodeObject] retain];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)inCoder
{
	[inCoder encodeObject:mName];
	[inCoder encodeObject:mParameters];
}

-(NSString *)name
{
	return mName;
}

-(void)setName:(NSString *)inName
{
	[mName autorelease];
	mName = [inName copy];
}

-(id)parameters
{
	return mParameters;
}

-(void)setParameters:(id)inParameters
{
	[mParameters autorelease];
	mParameters = [inParameters copy];
}

@end

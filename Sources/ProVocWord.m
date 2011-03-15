//
//  ProVocWord.m
//  ProVoc
//
//  Created by bovet on Sat Feb 08 2003.
//  Copyright (c) 2003 Arizona Software. All rights reserved.
//

#import "ProVocWord.h"

#import "ProVocPage.h"
#import "ProVocPreferences.h"
#import "StringExtensions.h"
#import "DateExtensions.h"
#import "ProVocInspector.h"
#import "ProVocTester.h"

@implementation ProVocWord

-(id)init
{
    if (self = [super init]) {
        mSourceWord = nil;
        mTargetWord = nil;
    }
    return self;
}

-(void)dealloc
{
    [mSourceWord release];
    [mTargetWord release];
    [mComment release];
	[mMedia release];
	[mLastAnswered release];
    [super dealloc];
}

-(id)initWithCoder:(NSCoder *)inCoder
{
    if (self = [super init]) {
        mPage = [inCoder decodeObjectForKey:@"ProVocPage"];
        mSourceWord = [[inCoder decodeObjectForKey:@"ProVocSourceWord"] retain];
        mTargetWord = [[inCoder decodeObjectForKey:@"ProVocTargetWord"] retain];
        mComment = [[inCoder decodeObjectForKey:@"ProVocComment"] retain];
        mRight = [inCoder decodeIntForKey:@"ProVocRight"];
        mWrong = [inCoder decodeIntForKey:@"ProVocWrong"];
		mDifficulty = [inCoder decodeFloatForKey:@"ProVocDifficulty"];
        mNumber = [inCoder decodeIntForKey:@"ProVocNumber"];
        mMark = [inCoder decodeIntForKey:@"ProVocMark"];
        mLabel = [inCoder decodeIntForKey:@"ProVocLabel"];
        mMedia = [[inCoder decodeObjectForKey:@"Media"] retain];
        mLastAnswered = [[inCoder decodeObjectForKey:@"LastAnswered"] retain];
        mIndexInFile = [inCoder decodeIntForKey:@"IndexInFile"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)inCoder
{
    [inCoder encodeConditionalObject:mPage forKey:@"ProVocPage"];
    [inCoder encodeObject:mSourceWord forKey:@"ProVocSourceWord"];
    [inCoder encodeObject:mTargetWord forKey:@"ProVocTargetWord"];
    [inCoder encodeObject:mComment forKey:@"ProVocComment"];
    [inCoder encodeInt:mRight forKey:@"ProVocRight"];
    [inCoder encodeInt:mWrong forKey:@"ProVocWrong"];
	[inCoder encodeFloat:mDifficulty forKey:@"ProVocDifficulty"];
    [inCoder encodeInt:mNumber forKey:@"ProVocNumber"];
    [inCoder encodeInt:mMark forKey:@"ProVocMark"];
    [inCoder encodeInt:mLabel forKey:@"ProVocLabel"];
	[inCoder encodeObject:mMedia forKey:@"Media"];
	[inCoder encodeObject:mLastAnswered forKey:@"LastAnswered"];
    [inCoder encodeInt:mIndexInFile forKey:@"IndexInFile"];
}

-(id)copyWithZone:(NSZone *)inZone
{
	return [[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self]] retain];
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"<%@ 0x%x %@ = %@>", NSStringFromClass([self class]), self, mSourceWord, mTargetWord];
}

-(void)setSourceWord:(NSString *)inSource
{
	if (mSourceWord != inSource) {
	    [mSourceWord release];
	    mSourceWord = [inSource retain];
	}
}

-(void)setTargetWord:(NSString *)inTarget
{
	if (mTargetWord != inTarget) {
	    [mTargetWord release];
    	mTargetWord = [inTarget retain];
	}
}

-(void)setComment:(NSString *)inComment
{
	if (mComment != inComment) {
	    [mComment release];
	    mComment = [inComment retain];
	}
}

-(int)mark
{
    return mMark;
}

-(void)setMark:(int)inMark
{
    mMark = inMark;
}

-(int)label
{
    return mLabel;
}

-(void)setLabel:(int)inLabel
{
    mLabel = inLabel;
}

-(NSString *)sourceWord
{
	if (!mSourceWord)
		mSourceWord = [@"" retain];
    return mSourceWord;
}

-(NSString *)targetWord
{
	if (!mTargetWord)
		mTargetWord = [@"" retain];
    return mTargetWord;
}

-(NSString *)comment
{
	if (!mComment)
		mComment = [@"" retain];
    return mComment;
}

-(void)swapSourceAndTarget:(id)inSender
{
	NSString *swap;
	switch ([inSender tag]) {
		case 0:
			swap = mSourceWord;
			mSourceWord = mTargetWord;
			mTargetWord = swap;
			[self swapSourceAndTargetMedia];
			break;
		case 1:
			swap = mSourceWord;
			mSourceWord = mComment ? mComment : [@"" retain];
			mComment = swap;
			break;
		case 2:
			swap = mTargetWord;
			mTargetWord = mComment ? mComment : [@"" retain];
			mComment = swap;
			break;
	}
}

-(void)increaseDifficulty
{
	mDifficulty += 1.0;
}

-(void)decreaseDifficulty
{
	mDifficulty -= 1.0;
}

-(void)resetDifficulty
{
    mRight = mWrong = 0;
	mDifficulty = 0.0;
}

-(void)reset
{
	[self resetDifficulty];
	[self resetLastAnswered];
}


-(void)removeAccents
{
	mSourceWord = [[[mSourceWord autorelease] stringByRemovingAccents] retain];
	mTargetWord = [[[mTargetWord autorelease] stringByRemovingAccents] retain];
}

-(int)right
{
    return mRight;
}

-(int)wrong
{
    return mWrong;
}

-(void)incrementRight
{
    mRight++;
	
	[mLastAnswered release];
	mLastAnswered = [[NSDate alloc] init];
}

-(void)incrementWrong
{
    mWrong++;
}

-(NSDate *)lastAnswered
{
	return mLastAnswered;
}

-(void)resetLastAnswered
{
	[mLastAnswered release];
	mLastAnswered = nil;
}

-(NSDate *)nextReview
{
	NSDate *lastAnswered = [self lastAnswered];
	if (!lastAnswered)
		return [[NSDate date] beginningOfDay];
	else
		return [lastAnswered addTimeInterval:[self reviewInterval]];
}

-(NSTimeInterval)reviewInterval
{
	float score = MAX(0, -[self difficulty]);
	float learningFactor = [[NSUserDefaults standardUserDefaults] floatForKey:PVReviewLearningFactor] / 50 - 1.0;
	learningFactor = exp(learningFactor * 1.09);
	// -1 => 0.33
	// 1 => 3.0
	score *= learningFactor;
	const float a = 34.244, b = 36.9532, c = 0.8361, d = 9.5751, e = 2.1031;
	score += 1.3;
	float days = a + b * tanh(c * (score - d)) + e * score;
	float trainingFactor = [[NSUserDefaults standardUserDefaults] floatForKey:PVReviewTrainingFactor] / 50;
	days *= trainingFactor;
	return days * 24 * 60 * 60;

}

-(int)number
{
    return mNumber;
}

-(void)setNumber:(int)inNumber
{
    mNumber = inNumber;
}

-(int)indexInFile
{
	return mIndexInFile;
}

-(void)setIndexInFile:(int)inIndex
{
	mIndexInFile = inIndex;
}

-(void)resetIndexInFile
{
	mIndexInFile = 0;
}

-(ProVocPage *)page
{
	return mPage;
}

-(void)setPage:(ProVocPage *)inPage
{
    mPage = inPage;
}

-(void)removeFromParent
{
	[[self page] removeWord:self];
}

-(float)difficulty
{
	float k = [[NSUserDefaults standardUserDefaults] floatForKey:PVPrefsRightRatio];
	if (k != 0)
		k = 1.0 / k;
    return mDifficulty + [self wrong] * k - [self right];
/*
    return mDifficulty + [self wrong] -
            [[NSUserDefaults standardUserDefaults] floatForKey:PVPrefsRightRatio] * [self right];
*/
}

-(BOOL)isDouble
{
	return mIsDouble;
}

-(void)setDouble:(id)inValue
{
	mIsDouble = [inValue boolValue];
}

@end

@implementation ProVocWord (Content)

-(NSString *)lastAnsweredDate
{
	NSDate *date = [self lastAnswered];
	if ([date isToday])
		return NSLocalizedString(@"Today", @"");
	if ([date isYersterday])
		return NSLocalizedString(@"Yesterday", @"");
	NSString *format = [[NSUserDefaults standardUserDefaults] objectForKey:NSShortDateFormatString];
	return [date descriptionWithCalendarFormat:format timeZone:nil locale:nil];
}

-(NSString *)nextReviewDate
{
	NSTimeInterval interval = [[self nextReview] timeIntervalSinceNow];
	if (![self lastAnswered] || interval <= 0)
		return NSLocalizedString(@"Now", @"");
	interval /= 60; // => minutes
	int minutes = MAX(1, floor(interval));
	if (minutes == 1)
		return NSLocalizedString(@"In one min.", @"");
	if (minutes > 10)
		minutes = round((float)minutes / 5) * 5;
	if (minutes < 60)
		return [NSString stringWithFormat:NSLocalizedString(@"In %i min.", @""), minutes]; 
	interval /= 60; // => hours
	int hours = floor(interval);
	if (hours == 1)
		return NSLocalizedString(@"In one hour", @"");
	if (hours < 24)
		return [NSString stringWithFormat:NSLocalizedString(@"In %i hours", @""), hours]; 
	interval /= 24; // => days
	int days = floor(interval);
	if (days == 1)
		return NSLocalizedString(@"In one day", @"");
	if (days < 7)
		return [NSString stringWithFormat:NSLocalizedString(@"In %i days", @""), days]; 
	interval /= 7; // => weeks
	int weeks = floor(interval);
	if (weeks == 1)
		return NSLocalizedString(@"In one week", @"");
	if (weeks < 4)
		return [NSString stringWithFormat:NSLocalizedString(@"In %i weeks", @""), weeks]; 

	NSString *format = [[NSUserDefaults standardUserDefaults] objectForKey:NSShortDateFormatString];
	return [[self nextReview] descriptionWithCalendarFormat:format timeZone:nil locale:nil];
}

-(id)objectForIdentifier:(id)inIdentifier
{
    if ([inIdentifier isEqualTo:@"Source"])
        return [self sourceWord];
    else if ([inIdentifier isEqualTo:@"Target"])
        return [self targetWord];
    else if ([inIdentifier isEqualTo:@"Comment"])
        return [self comment];
    else if ([inIdentifier isEqualTo:@"Difficulty"])
        return [NSNumber numberWithFloat:[self difficulty]];
    else if ([inIdentifier isEqualTo:@"Number"])
        return [NSNumber numberWithInt:[self number]];
    else if ([inIdentifier isEqualTo:@"Mark"])
        return [self mark] == 0 ? nil : [NSImage imageNamed:@"flagged"];
    else if ([inIdentifier isEqualTo:@"MarkAndLabel"])
		return [NSNumber numberWithInt:mLabel + mMark * 512];
    else if ([inIdentifier isEqualTo:@"LastAnswered"])
		return [self lastAnsweredDate];
    else if ([inIdentifier isEqualTo:@"NextReview"])
		return [self nextReviewDate];
    else
        return nil;
}

-(void)setObject:(id)inObject forIdentifier:(id)inIdentifier
{
    if ([inIdentifier isEqualTo:@"Source"])
        [self setSourceWord:inObject];
    else if ([inIdentifier isEqualTo:@"Target"])
        [self setTargetWord:inObject];
    else if ([inIdentifier isEqualTo:@"Comment"])
        [self setComment:inObject];
}

-(void)clearValueForIdentifier:(id)inIdentifier
{
    if ([inIdentifier isEqualTo:@"Source"])
        [self setSourceWord:@""];
    else if ([inIdentifier isEqualTo:@"Target"])
        [self setTargetWord:@""];
    else if ([inIdentifier isEqualTo:@"Comment"])
        [self setComment:@""];
    else if ([inIdentifier isEqualTo:@"Mark"]) {
        [self setMark:0];
		[self setLabel:0];
	} else if ([inIdentifier isEqualTo:@"Difficulty"])
		[self resetDifficulty];
	else if ([inIdentifier isEqualTo:@"LastAnswered"])
		[self resetLastAnswered];
}

-(id)valueForIdentifier:(id)inIdentifier
{
    if ([inIdentifier isEqualTo:@"Mark"])
        return [NSNumber numberWithInt:[self mark]];
	else if ([inIdentifier isEqualTo:@"LastAnswered"])
        return mLastAnswered ? mLastAnswered : [NSDate distantPast];
	else if ([inIdentifier isEqualTo:@"NextReview"])
        return [self nextReview];
    else
        return [self objectForIdentifier:inIdentifier];
}

@end

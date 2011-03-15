//
//  DateExtensions.m
//  ProVoc
//
//  Created by Simon Bovet on 25.02.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "DateExtensions.h"


@implementation NSDate (Extensions)

-(NSDate *)beginningOfDay
{
	NSMutableString *description = [[self description] mutableCopy];
	[description replaceCharactersInRange:NSMakeRange(11, 8) withString:@"00:00:00"];
	NSDate *date = [NSDate dateWithString:description];
	[description release];
	return date;
}

-(NSDate *)beginningOfNextDay
{
	return [[self beginningOfDay] nextDay];
}

-(NSDate *)previousDay
{
	return [self addTimeInterval:-24 * 60 * 60];
}

-(NSDate *)nextDay
{
	return [self addTimeInterval:24 * 60 * 60];
}

-(NSDate *)beginningOfWeek
{
	return [[self beginningOfNextWeek] previousWeek];
}

-(NSDate *)beginningOfNextWeek
{
	return [[self beginningOfDay] nextDay];
}

-(NSDate *)previousWeek
{
	return [self addTimeInterval:-7 * 24 * 60 * 60];
}

-(NSDate *)nextWeek
{
	return [self addTimeInterval:7 * 24 * 60 * 60];
}

-(NSDate *)beginningOfMonth
{
	NSMutableString *description = [[self description] mutableCopy];
	[description replaceCharactersInRange:NSMakeRange(8, 11) withString:@"01 03:00:00"];
	NSDate *date = [NSDate dateWithString:description];
	[description release];
	return date;
}

-(NSDate *)beginningOfNextMonth
{
	return [[self beginningOfMonth] nextMonth];
}

-(int)year
{
	return [[[self description] substringWithRange:NSMakeRange(0, 4)] intValue];
}

-(int)month
{
	return [[[self description] substringWithRange:NSMakeRange(5, 2)] intValue];
}

-(NSDate *)previousMonth
{
	int year = [self year];
	int month = [self month];
	if (month > 1)
		month--;
	else {
		year--;
		month = 12;
	}
	NSMutableString *description = [[self description] mutableCopy];
	[description replaceCharactersInRange:NSMakeRange(0, 4) withString:[NSString stringWithFormat:@"%04i", year]];
	[description replaceCharactersInRange:NSMakeRange(5, 2) withString:[NSString stringWithFormat:@"%02i", month]];
	NSDate *date = [NSDate dateWithString:description];
	[description release];
	return date;
}

-(NSDate *)nextMonth
{
	int year = [self year];
	int month = [self month];
	if (month < 12)
		month++;
	else {
		year++;
		month = 1;
	}
	NSMutableString *description = [[self description] mutableCopy];
	[description replaceCharactersInRange:NSMakeRange(0, 4) withString:[NSString stringWithFormat:@"%04i", year]];
	[description replaceCharactersInRange:NSMakeRange(5, 2) withString:[NSString stringWithFormat:@"%02i", month]];
	NSDate *date = [NSDate dateWithString:description];
	[description release];
	return date;
}

-(BOOL)isToday
{
	NSDate *date = [NSDate date];
	return [self isBetweenDate:[date beginningOfDay] andDate:[date beginningOfNextDay]];
}

-(BOOL)isYersterday
{
	NSDate *date = [[NSDate date] previousDay];
	return [self isBetweenDate:[date beginningOfDay] andDate:[date beginningOfNextDay]];
}

-(BOOL)isBetweenDate:(NSDate *)inFrom andDate:(NSDate *)inTo
{
	return [inFrom compare:self] != NSOrderedDescending && [self compare:inTo] == NSOrderedAscending;
}

@end

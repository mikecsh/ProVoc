//
//  DateExtensions.h
//  ProVoc
//
//  Created by Simon Bovet on 25.02.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSDate (Extensions)

-(NSDate *)beginningOfDay;
-(NSDate *)beginningOfNextDay;
-(NSDate *)previousDay;
-(NSDate *)nextDay;

-(NSDate *)beginningOfWeek;
-(NSDate *)beginningOfNextWeek;
-(NSDate *)previousWeek;
-(NSDate *)nextWeek;

-(NSDate *)beginningOfMonth;
-(NSDate *)beginningOfNextMonth;
-(NSDate *)previousMonth;
-(NSDate *)nextMonth;

-(BOOL)isToday;
-(BOOL)isYersterday;

-(BOOL)isBetweenDate:(NSDate *)inFrom andDate:(NSDate *)inTo;

-(int)year;
-(int)month;

@end

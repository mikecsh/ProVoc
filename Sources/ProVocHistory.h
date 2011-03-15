//
//  ProVocHistory.h
//  ProVoc
//
//  Created by Simon Bovet on 25.02.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define MAX_HISTORY_REPETITION 3

@interface ProVocHistory : NSObject {
	NSDate *mDate;
	int mMode;
	NSMutableArray *mRepetitions;
}

+(NSColor *)colorForRepetition:(int)inRepetition;

-(void)setDate:(NSDate *)inDate;
-(void)setMode:(int)inMode;
-(void)setNumber:(int)inNumber ofRepetition:(int)inRepetition;
-(void)addNumber:(int)inNumber ofRepetition:(int)inRepetition;
-(void)addHistory:(ProVocHistory *)inHistory;

-(int)total;
-(NSDate *)date;
-(int)numberOfRepetition:(int)inRepetition;

@end

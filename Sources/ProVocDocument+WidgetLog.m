//
//  ProVocDocument+WidgetLog.m
//  ProVoc
//
//  Created by Simon Bovet on 08.08.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ProVocDocument+WidgetLog.h"
#import "ProVocDocument+Lists.h"

#import "ProVocWord.h"
#import "ProVocHistory.h"
#import "ScannerExtensions.h"

@interface ProVocWord (WidgetLog)

-(void)logSuccess:(int)inSuccess date:(NSDate *)inDate;

@end

@implementation ProVocDocument (WidgetLog)

-(void)reindexWordsInFile
{
	NSEnumerator *enumerator = [[self allWords] objectEnumerator];
	ProVocWord *word;
	int index = 1;
	while (word = [enumerator nextObject])
		[word setIndexInFile:index++];
}

-(ProVocWord *)wordWithIndexInFile:(int)inIndex
{
	NSEnumerator *enumerator = [[self allWords] objectEnumerator];
	ProVocWord *word = nil;
	while (word = [enumerator nextObject])
		if ([word indexInFile] == inIndex)
			break;
	return word;
}

-(void)updateCurrentWidgetLogHistoryWithDate:(NSDate *)inDate
{
	if (!mCurrentWidgetLogHistory) {
		mCurrentWidgetLogHistory = [[ProVocHistory alloc] init];
		[self willChangeValueForKey:@"canClearHistory"];
		if (!mHistories)
			mHistories = [[NSMutableArray alloc] initWithCapacity:0];
		[mHistories addObject:mCurrentWidgetLogHistory];
		[self didChangeValueForKey:@"canClearHistory"];
	}
	
	int i;
	for (i = 0; i <= MAX_HISTORY_REPETITION; i++)
		[mCurrentWidgetLogHistory setNumber:0 ofRepetition:i];

	NSEnumerator *enumerator = [mCurrentWidgetRepetitions objectEnumerator];
	id repetition;
	while (repetition = [enumerator nextObject]) {
		int rep = MIN([repetition intValue], MAX_HISTORY_REPETITION);
		[mCurrentWidgetLogHistory addNumber:1 ofRepetition:rep];
	}
	[mCurrentWidgetRepetitions setObject:inDate forKey:@"lastDate"];
	[mCurrentWidgetLogHistory setDate:inDate];
	[mHistoryView reloadData];
}

-(void)checkWidgetLog
{
	BOOL anythingLogged = NO;
	NSDate *lastDate = [mCurrentWidgetRepetitions objectForKey:@"lastDate"];
	NSString *logFile = [[self fileName] stringByAppendingPathComponent:@"Widget.log"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:logFile]) {
		NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:logFile traverseLink:NO];
		NSDate *modificationDate = [fileAttributes objectForKey:NSFileModificationDate];
		if (modificationDate && (!mLastWidgetLogModificationDate || [modificationDate compare:mLastWidgetLogModificationDate] == NSOrderedDescending)) {
			[mLastWidgetLogModificationDate release];
			mLastWidgetLogModificationDate = [modificationDate retain];
			
			NSScanner *scanner = [NSScanner scannerWithString:[NSString stringWithContentsOfFile:logFile encoding:NSUTF8StringEncoding error:nil]];
			[scanner setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
			if (![scanner scanString:@"WidgetLog v" intoString:nil])
				NSLog(@"*** Invalid Widget Log File ***");
			else {
				float version;
				if (![scanner scanFloat:&version] || version > 1.0)
					NSLog(@"*** Invalid Widget Log File Version ***");
				else {
					int linesRead = 0;
					while (![scanner isAtEnd]) {
						[scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:nil];
						
						NSString *dateDescription;
						int index = -1, success = -1;
						BOOL read = NO;
						if ([scanner scanUpToString:@"=" intoString:&dateDescription]) {
							[scanner scanString:@"=" intoString:nil];
							if ([scanner scanInt:&index] && [scanner scanInt:&success]) {
								read = YES;
								linesRead++;
								if (linesRead > mLinesReadInWidgetLog) {
									mLinesReadInWidgetLog++;
									dateDescription = [dateDescription stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
									NSDate *date = [NSDate dateWithString:dateDescription];
									ProVocWord *word = [self wordWithIndexInFile:index];
									[word logSuccess:success date:date];
									anythingLogged = YES;
									
									if (lastDate && [date timeIntervalSinceDate:lastDate] > 30 * 60) {
										[self updateCurrentWidgetLogHistoryWithDate:lastDate];
										[mCurrentWidgetRepetitions release];
										mCurrentWidgetRepetitions = nil;
										[mCurrentWidgetLogHistory release];
										mCurrentWidgetLogHistory = nil;
									}

									lastDate = date;
									if (!mCurrentWidgetRepetitions)
										mCurrentWidgetRepetitions = [[NSMutableDictionary alloc] initWithCapacity:0];
									id repetitionKey = [NSNumber numberWithInt:index];
									int repetition = [[mCurrentWidgetRepetitions objectForKey:repetitionKey] intValue];
									if (!success)
										repetition++;
									[mCurrentWidgetRepetitions setObject:[NSNumber numberWithInt:repetition] forKey:repetitionKey];
								}
							}
						}
						if (!read)
							break;
					}
				}
			}
		}
	}
	
	if (anythingLogged) {
		[self rightRatioDidChange:nil];
		[self updateCurrentWidgetLogHistoryWithDate:lastDate];
	}
}

-(void)finalCheckWidgetLog
{
	[self checkWidgetLog];
	[mLastWidgetLogModificationDate release];
	mLastWidgetLogModificationDate = nil;
	mLinesReadInWidgetLog = 0;
	[mCurrentWidgetLogHistory release];
	mCurrentWidgetLogHistory = nil;
	[mCurrentWidgetRepetitions release];
	mCurrentWidgetRepetitions = nil;
}

@end

@implementation ProVocWord (WidgetLog)

-(void)logSuccess:(int)inSuccess date:(NSDate *)inDate
{
	if (inSuccess) {
	    mRight++;
		[mLastAnswered release];
		mLastAnswered = [inDate retain];
	} else
		mWrong++;
}

@end


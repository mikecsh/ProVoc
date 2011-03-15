//
//  ProVocHistoryView.h
//  ProVoc
//
//  Created by Simon Bovet on 25.02.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ProVocHistory.h"

@interface ProVocHistoryView : NSView {
	IBOutlet id mDataSource;
	NSMutableArray *mBins;
	int mTotal;
	int mNumberOfBins;
	int mDisplay;
	
	NSDate *mReferenceDate;
	int mHistoryIndex;
}

-(int)display;
-(void)setDisplay:(int)inDisplay;

-(void)reloadData;

@end

@protocol ProVocHistoryDataSource

-(int)numberOfHistories;
-(ProVocHistory *)historyAtIndex:(int)inIndex;

@end
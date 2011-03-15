//
//  ProVocMCQTester.h
//  ProVoc
//
//  Created by Simon Bovet on 06.10.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ProVocTester.h"

@interface ProVocMCQTester : ProVocTester {
	NSArray *mAnswerWords;
	NSMutableArray *mSources;
	NSMutableArray *mTargets;
	NSMutableDictionary *mLabeledSources;
	NSMutableDictionary *mLabeledTargets;
	int mNumberOfChoices;
	BOOL mDelayedChoices;
	BOOL mDelayingChoices;
}

-(void)setAnswerWords:(NSArray *)inWords withParameters:(id)inParameters;

@end

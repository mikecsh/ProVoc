//
//  ProVocTimer.h
//  ProVoc
//
//  Created by Simon Bovet on 15.05.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ProVocTimerView.h"
#define ProVocTimerRemainingTimeDidElapseNotification @"ProVocTimerRemainingTimeDidElapseNotification"

@interface ProVocTimer : NSWindowController {
	IBOutlet ProVocTimerView *mTimerView;
	
	NSWindow *mWindow;
	NSTimeInterval mStartTime;
	NSTimeInterval mPauseTime;
	NSTimeInterval mRemainingTime;
	NSTimeInterval mAdditionalTime;
	BOOL mNotifyElapse;
}

-(void)setRemainingTime:(NSTimeInterval)inTimeInterval;
-(void)addRemainingTime:(NSTimeInterval)inTimeInterval;

-(void)start;
-(void)pause;
-(void)stop;
-(void)hide;

@end

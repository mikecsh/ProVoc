//
//  ProVocTimerView.h
//  ProVoc
//
//  Created by Simon Bovet on 15.05.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ProVocTimerView : NSView {
	NSTimeInterval mTime;
	BOOL mCountingDown;
}

-(void)setTime:(NSTimeInterval)inTime;
-(void)setCountingDown:(BOOL)inCountingDown;

@end

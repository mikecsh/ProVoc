//
//  ProVocResultView.h
//  ProVoc
//
//  Created by Simon Bovet on 25.02.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ProVocResultView : NSView {
	NSMutableArray *mResults;
	int mTotal;
}

-(void)removeResults;
-(void)addResult:(NSString *)inTitle value:(int)inValue color:(NSColor *)inColor;

@end

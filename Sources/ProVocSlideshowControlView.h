//
//  ProVocSlideshowControlView.h
//  ProVoc
//
//  Created by Simon Bovet on 12.10.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ProVocSlideshowControlView : NSView {
	NSDictionary *mControlPaths;
	NSMutableArray *mControls;
	NSString *mHighlight;
}

-(void)highlightControl:(id)inControl;
-(void)setControl:(id)inControl;

@end


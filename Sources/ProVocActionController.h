//
//  ProVocActionController.h
//  ProVoc
//
//  Created by Simon Bovet on 03.11.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ProVocActionController : NSWindowController {
	NSString *mActionTitle;
	id mDelegate;
	SEL mCancelSelector;
	float mProgress;
}

+(id)actionControllerWithTitle:(NSString *)inTitle modalWindow:(NSWindow *)inWindow delegate:(id)inDelegate cancelSelector:(SEL)inCancelSelector;
-(id)initWithTitle:(NSString *)inTitle delegate:(id)inDelegate cancelSelector:(SEL)inCancelSelector;
-(void)setProgress:(id)inProgress;
-(void)finish;

-(IBAction)cancel:(id)inSender;

@end

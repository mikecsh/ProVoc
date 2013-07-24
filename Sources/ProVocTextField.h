//
//  ProVocTextField.h
//  ProVoc
//
//  Created by Simon Bovet on 14.10.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define ProVocTextFieldDidBecomeFirstResponderNotification @"ProVocTextFieldDidBecomeFirstResponderNotification"

@interface ProVocTextField : NSTextField {
	IBOutlet id mPreviousField;
	IBOutlet id mNextField;
}

-(id)chainedResponder:(int)inOffset;

@end

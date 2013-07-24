//
//  ProVocTextField.m
//  ProVoc
//
//  Created by Simon Bovet on 14.10.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import "ProVocTextField.h"


@implementation ProVocTextField

-(id)chainedResponder:(int)inOffset
{
	return inOffset < 0 ? mPreviousField : mNextField;
}

-(BOOL)becomeFirstResponder
{
	BOOL ok = [super becomeFirstResponder];
	if (ok)
		[[NSNotificationCenter defaultCenter] postNotificationName:ProVocTextFieldDidBecomeFirstResponderNotification object:self];
	return ok;
}

@end

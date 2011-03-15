//
//  ProVocFontNameField.h
//  ProVoc
//
//  Created by Simon Bovet on 27.11.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ProVocFontNameField : NSTextField {
	NSMutableDictionary *mObservedObjects;
	NSMutableDictionary *mObservedKeyPaths;
}

-(IBAction)userSetFont:(id)inSender;

+(BOOL)changeFont:(id)inSender;

@end

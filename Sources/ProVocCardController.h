//
//  ProVocCardController.h
//  ProVoc
//
//  Created by Simon Bovet on 12.05.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define ProVocCardFormat @"cardFormat"
#define ProVocCardCustomWidth @"cardCustomWidth"
#define ProVocCardCustomHeight @"cardCustomHeight"

@class ProVocCardPreview;
@class ProVocDocument;

@interface ProVocCardController : NSWindowController {
	IBOutlet ProVocCardPreview *mPreview;
	ProVocDocument *mDocument;
	NSArray *mWords;
	int mWordIndex;
	BOOL mContainComments;
	BOOL mContainImages;
}

-(id)initWithDocument:(ProVocDocument *)inDocument words:(NSArray *)inWords;

-(BOOL)runModal;

-(IBAction)confirm:(id)inSender;
-(IBAction)sizeUnitDidChange:(id)inSender;
-(IBAction)formatDidChange:(id)inSender;

@end

@class ProVocWord;

@interface ProVocCardPreview : NSView {
	ProVocDocument *mDocument;
	ProVocWord *mWord;
}

-(void)setDocument:(ProVocDocument *)inDocument;
-(void)setWord:(ProVocWord *)inWord;
-(IBAction)update:(id)inSender;

@end

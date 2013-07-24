//
//  ProVocPrintView.h
//  ProVoc
//
//  Created by Simon Bovet on 12.10.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ProVocDocument.h"

#define ProVocPrintComments @"printComments"
#define ProVocPrintPageNumbers @"printPageNumbers"
#define PVPrintListFontSize @"printListFontSize"

@interface ProVocPrintView : NSView {
	ProVocDocument *mDocument;
	NSArray *mProVocPages;
	NSMutableArray *mPages;
	NSString *mPageTitle;
	NSSize mPaperSize;
	NSMutableDictionary *mCurrentPage;
	NSMutableArray *mCurrentWords;
	float mCurrentPageTop;
	float mCurrentY;
}

-(id)initWithDocument:(ProVocDocument *)inDocument;

-(void)updatePagination:(NSPrintOperation *)inPrintOperation;

@end

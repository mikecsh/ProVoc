//
//  ProVocDocument+Export.h
//  ProVoc
//
//  Created by Simon Bovet on 01.11.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ProVocDocument.h"
#import "ProVocWord.h"
#import "ProVocPage.h"

#define PVExportFormat @"exportFormat"
#define PVExportComments @"exportComments"
#define PVExportPageNames @"exportPageNames"

@interface ProVocDocument (Export)

-(NSString *)stringFromPages:(NSArray *)inPages;
-(NSString *)stringFromWords:(NSArray *)inWords;
-(NSString *)exportString;

@end

@interface ProVocDocument (Import)

-(NSArray *)wordsFromString:(NSString *)inString;
-(void)concludeNewImport;

@end

@interface NSApplication (Import)

-(void)importWordsFromFiles:(NSArray *)inFileNames inNewDocument:(BOOL)inNewDocument;
-(IBAction)import:(id)inSender;

@end

@interface ProVocText : NSObject {
	NSString *mContents;
}

-(id)initWithContents:(NSString *)inContents;
-(NSString *)contents;

@end
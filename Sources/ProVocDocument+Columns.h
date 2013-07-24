//
//  ProVocDocument+Columns.h
//  ProVoc
//
//  Created by Simon Bovet on 26.05.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ProVocDocument.h"

@interface ProVocDocument (Columns)

-(void)initializeColumns;

-(BOOL)validate:(BOOL *)outFlag columnMenuItem:(NSMenuItem *)inItem;
-(void)makeColumnWithIdentifier:(NSString *)inIdentifier visible:(BOOL)inVisible;

-(NSMutableDictionary *)columnVisibility;
-(void)setColumnVisibility:(NSDictionary *)inVisibility;

-(IBAction)viewOptions:(id)inSender;

@end

@interface ProVocViewOptions : NSWindowController {
	ProVocDocument *mDocument;
	NSMutableDictionary *mColumnVisibility;
}

-(id)initWithDocument:(ProVocDocument *)inDocument;

-(void)runModal;
-(IBAction)close:(id)inSender;

@end

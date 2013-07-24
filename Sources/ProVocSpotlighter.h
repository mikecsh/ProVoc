//
//  ProVocSpotlighter.h
//  ProVoc
//
//  Created by Simon Bovet on 15.05.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ProVocSpotlighter : NSWindowController {
	NSMetadataQuery *mQuery;
	NSString *mSearchString;
}

-(NSArray *)allProVocFiles;
-(NSArray *)allProVocFilesContaining:(NSString *)inSearchString;

-(IBAction)cancel:(id)inSender;

@end

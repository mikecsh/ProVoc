//
//  ProVocDocument+WidgetLog.h
//  ProVoc
//
//  Created by Simon Bovet on 08.08.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ProVocDocument.h"

@interface ProVocDocument (WidgetLog)

-(void)reindexWordsInFile;
-(void)checkWidgetLog;
-(void)finalCheckWidgetLog;

@end

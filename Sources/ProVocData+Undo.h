//
//  ProVocData+Undo.h
//  ProVoc
//
//  Created by Simon Bovet on 07.05.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ProVocData.h"
#import "ProVocWord.h"

@interface ProVocData (Undo)

-(NSData *)dataForWord:(ProVocWord *)inWord;
-(id)identifierForWord:(ProVocWord *)inWord;

-(NSData *)dataForSource:(ProVocSource *)inSource;
-(id)identifierForSource:(ProVocSource *)inSource;

-(id)childWithIdentifier:(id)inIdentifier;

@end

@interface ProVocSource (Undo)

-(id)indexIdentifier;
-(id)childWithIndexes:(NSArray *)inIndexes;

@end

@interface ProVocWord (Undo)

-(id)indexIdentifier;

@end
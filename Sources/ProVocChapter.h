//
//  ProVocChapter.h
//  ProVoc
//
//  Created by Simon Bovet on 31.10.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ProVocData.h"

@interface ProVocChapter : ProVocSource {
    NSMutableArray *mChildren;
}

-(void)addChild:(id)inChild;
-(void)addChildren:(NSArray *)inChildren;
-(void)insertChild:(id)inChild atIndex:(int)inIndex;
-(void)insertChildren:(NSArray *)inChildren atIndex:(int)inIndex;
-(void)removeChild:(id)inChild;

-(NSArray *)children;
-(BOOL)isAncestorOf:(id)inChild;

-(NSArray *)allPages;

@end

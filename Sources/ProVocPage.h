//
//  ProVocPage.h
//  ProVoc
//
//  Created by bovet on Sun Feb 09 2003.
//  Copyright (c) 2003 Arizona Software. All rights reserved.
//

#import "ProVocData.h"
#import "ProVocWord.h"

@interface ProVocPage : ProVocSource {
    NSMutableArray *mWords;
}

-(NSArray *)words;

-(void)addWord:(ProVocWord *)inWord;
-(void)addWords:(NSArray *)inWords;
-(void)insertWord:(ProVocWord *)inWord atIndex:(int)inIndex;
-(void)insertWords:(NSArray *)inWords atIndex:(int)inIndex;

-(void)removeWord:(ProVocWord *)inWord;
-(void)removeWords:(NSArray *)inWords;

@end

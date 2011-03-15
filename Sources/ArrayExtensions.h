//
//  ArrayExtensions.h
//  ProVoc
//
//  Created by Simon Bovet on 06.10.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSArray (Shuffle)

-(NSArray *)shuffledArray;
-(id)randomObject;

@end

@interface NSArray (DeepCopy)

-(id)deepMutableCopy;

@end

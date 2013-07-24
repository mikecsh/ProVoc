//
//  ProVocPreset.h
//  ProVoc
//
//  Created by Simon Bovet on 26.01.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ProVocPreset : NSObject <NSCoding, NSCopying> {
	NSString *mName;
	id mParameters;
}

-(NSString *)name;
-(void)setName:(NSString *)inName;

-(id)parameters;
-(void)setParameters:(id)inParameters;

@end

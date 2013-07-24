//
//  ZIPCompresser.h
//  FTPTest
//
//  Created by Simon Bovet on 08.05.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ZIPCompresser : NSObject {
	NSTask *mTask;
	
	id mDelegate;
}

-(id)initWithFile:(NSString *)inFile destination:(NSString *)inDestination;

-(void)setDelegate:(id)inDelegate;
-(void)startCompress;
-(void)cancelCompress;

@end

@interface NSObject (ZIPCompresserDelegate)

-(void)compresser:(ZIPCompresser *)inCompresser didFinishWithCode:(int)inCode;

@end
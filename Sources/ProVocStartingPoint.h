//
//  ProVocStartingPoint.h
//  ProVoc
//
//  Created by Simon Bovet on 07.05.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define ProVocShowStartingPoint @"StartingPoint"

@interface ProVocStartingPoint : NSWindowController {

}

+(ProVocStartingPoint *)defaultStartingPoint;
-(void)idle;

-(IBAction)newDocument:(id)inSender;
-(IBAction)openDocument:(id)inSender;
-(IBAction)downloadDocument:(id)inSender;

@end

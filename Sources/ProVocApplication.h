//
//  ProVocApplication.h
//  ProVoc
//
//  Created by Simon Bovet on 14.10.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ProVocApplication : NSApplication {

}

@end

@interface NSApplication (ProVoc)

-(long)systemVersion;

@end

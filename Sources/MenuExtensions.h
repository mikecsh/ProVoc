//
//  MenuExtensions.h
//  ProVoc
//
//  Created by Simon Bovet on 14.02.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSMenu (ProVoc)

-(void)addItemWithTitle:(NSString *)inTitle target:(id)inTarget selector:(SEL)inSelector;

@end

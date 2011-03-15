//
//  WindowExtensions.h
//  ProVoc
//
//  Created by Simon Bovet on 08.10.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSWindow (Shake)

-(void)shake;

-(void)setContentSize:(NSSize)inSize keepTopLeftCorner:(BOOL)inKeepTopLeftCorner;

@end


@interface NSView (ClassSubview)

-(NSView *)subviewOfClass:(Class)inClass;

@end


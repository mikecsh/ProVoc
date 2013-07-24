//
//  BezierPathExtensions.h
//  ProVoc
//
//  Created by Simon Bovet on 08.10.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSBezierPath (RoundRect)

+(NSBezierPath *)bezierPathWithUpperRoundRectInRect:(NSRect)inRect radius:(float)inRadius;
+(NSBezierPath *)bezierPathWithRoundRectInRect:(NSRect)inRect radius:(float)inRadius;

@end

@interface NSBezierPath (Shading)

-(void)fillWithColors:(NSArray *)inColors angleInDegrees:(float)inDegrees;
-(void)fillWithAquaColor:(NSColor *)inColor angleInDegrees:(float)inDegrees;

@end


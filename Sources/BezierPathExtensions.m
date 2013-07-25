//
//  BezierPathExtensions.m
//  ProVoc
//
//  Created by Simon Bovet on 08.10.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import "BezierPathExtensions.h"


@implementation NSBezierPath (RoundRect)

+(NSBezierPath *)bezierPathWithUpperRoundRectInRect:(NSRect)inRect radius:(float)inRadius
{
   NSBezierPath *path = [self bezierPath];
   float radius = MIN(inRadius, 0.5f * MIN(NSWidth(inRect), NSHeight(inRect)));
   NSRect rect = NSInsetRect(inRect, radius, radius);
   [path moveToPoint:NSMakePoint(NSMinX(inRect), NSMinY(inRect))];
   [path lineToPoint:NSMakePoint(NSMaxX(inRect), NSMinY(inRect))];
   [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMaxY(rect)) radius:radius startAngle:  0.0 endAngle: 90.0];
   [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMaxY(rect)) radius:radius startAngle: 90.0 endAngle:180.0];
   [path closePath];
   return path;
}

+(NSBezierPath *)bezierPathWithRoundRectInRect:(NSRect)inRect radius:(float)inRadius
{
   NSBezierPath *path = [self bezierPath];
   float radius = MIN(inRadius, 0.5f * MIN(NSWidth(inRect), NSHeight(inRect)));
   NSRect rect = NSInsetRect(inRect, radius, radius);
   [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMinY(rect)) radius:radius startAngle:180.0 endAngle:270.0];
   [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMinY(rect)) radius:radius startAngle:270.0 endAngle:360.0];
   [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMaxY(rect)) radius:radius startAngle:  0.0 endAngle: 90.0];
   [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMaxY(rect)) radius:radius startAngle: 90.0 endAngle:180.0];
   [path closePath];
   return path;
}

@end

@implementation NSBezierPath (Shading)

static void sGetShadingComponents(void *info, const float *inData, float *outData)
{
	NSArray *array = (NSArray *)info;
	NSColor *color = [[array objectAtIndex:0] blendedColorWithFraction:*inData ofColor:[array objectAtIndex:1]];
    [color getRed:&outData[0] green:&outData[1] blue:&outData[2] alpha:&outData[3]];
}

static void sGetAquaShadingComponents(void *info, const float *inData, float *outData)
{
	NSColor *color = (NSColor *)info;
	const float k = *inData;
	if (k < 0.5)
		color = [color blendedColorWithFraction:0.5 * k ofColor:[NSColor whiteColor]];
	else
		color = [color blendedColorWithFraction:0.5 * (1.0 - k) ofColor:[NSColor blackColor]];
    [color getRed:&outData[0] green:&outData[1] blue:&outData[2] alpha:&outData[3]];
}

static float sRanges[8] = {0, 1, 0, 1, 0, 1, 0, 1};

-(void)fillWithAngleInDegrees:(float)inDegrees info:(void *)inInfo callback:(CGFunctionEvaluateCallback)inCallback
{
    float alpha = inDegrees / 180.0 * M_PI;
    float dx = cos(alpha);
    float dy = sin(alpha);
    int i, n = [self elementCount];
    NSPoint points[3];
    float d, dmin = 0, dmax = 1;
    BOOL first = YES;
    
    for (i = 0; i < n; i++)
        if ([self elementAtIndex:i associatedPoints:points] != NSClosePathBezierPathElement) {
            d = points[0].x * dx + points[0].y * dy;
            if (first) {
                dmin = dmax = d;
                first = NO;
            } else if (d < dmin)
                dmin = d;
            else if (d > dmax)
                dmax = d;
        }

    [NSGraphicsContext saveGraphicsState];
    [self addClip];
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	CGPoint start = CGPointMake(dmin * dx, dmin * dy);
	CGPoint end = CGPointMake(dmax * dx, dmax * dy);
    
    CGFunctionCallbacks callbacks;
    callbacks.version = 0;
    callbacks.evaluate = inCallback;
    callbacks.releaseInfo = nil;
    CGFunctionRef function = CGFunctionCreate(inInfo, 1, sRanges, 4, sRanges, &callbacks);

    CGShadingRef shading = CGShadingCreateAxial(colorSpace, start, end, function, YES, YES);
    
    CGContextDrawShading((CGContextRef)[[NSGraphicsContext currentContext] graphicsPort], shading);
    
    CGShadingRelease(shading);
    CGFunctionRelease(function);
    CGColorSpaceRelease(colorSpace);
    
    [NSGraphicsContext restoreGraphicsState];
}

-(void)fillWithColors:(NSArray *)inColors angleInDegrees:(float)inDegrees
{
	[self fillWithAngleInDegrees:inDegrees info:inColors callback:&sGetShadingComponents];
}

-(void)fillWithAquaColor:(NSColor *)inColor angleInDegrees:(float)inDegrees
{
	[self fillWithAngleInDegrees:inDegrees info:inColor callback:&sGetAquaShadingComponents];
}

@end


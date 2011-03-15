//
//  SplitViewExtensions.m
//  ProVoc
//
//  Created by Simon Bovet on 24.02.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "SplitViewExtensions.h"


@implementation NSSplitView (Extensions)

-(id)splitViewState
{
	NSMutableArray *subviewSizes = [NSMutableArray array];
	NSEnumerator *enumerator = [[self subviews] objectEnumerator];
	NSView *subview;
	while (subview = [enumerator nextObject]) {
		NSSize size = [subview frame].size;
		if ([self isVertical])
			[subviewSizes addObject:[NSNumber numberWithFloat:size.width]];
		else
			[subviewSizes addObject:[NSNumber numberWithFloat:size.height]];
	}
	return [NSDictionary dictionaryWithObject:subviewSizes forKey:@"SubviewSizes"];
}

-(void)setSplitViewState:(id)inState
{
	NSEnumerator *viewEnumerator = [[self subviews] objectEnumerator];
	NSView *subview;
	NSEnumerator *sizeEnumerator = [[inState objectForKey:@"SubviewSizes"] objectEnumerator];
	NSNumber *size;
	while ((subview = [viewEnumerator nextObject]) && (size = [sizeEnumerator nextObject]))
		if ([self isVertical])
			[subview setFrameSize:NSMakeSize([size floatValue], [subview frame].size.height)];
		else
			[subview setFrameSize:NSMakeSize([subview frame].size.width, [size floatValue])];
	[self adjustSubviews];
}

@end

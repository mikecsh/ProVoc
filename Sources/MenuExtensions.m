//
//  MenuExtensions.m
//  ProVoc
//
//  Created by Simon Bovet on 14.02.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "MenuExtensions.h"


@implementation NSMenu (ProVoc)

-(void)addItemWithTitle:(NSString *)inTitle target:(id)inTarget selector:(SEL)inSelector
{
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:inTitle action:inSelector keyEquivalent:@""];
	[item setTarget:inTarget];
	[self addItem:item];
	[item release];
}

@end

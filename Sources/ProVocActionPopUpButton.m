//
//  ProVocActionPopUpButton.m
//  ProVoc
//
//  Created by Simon Bovet on 24.02.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ProVocActionPopUpButton.h"


@implementation ProVocActionPopUpButton

-(id)initWithFrame:(NSRect)inFrameRect pullsDown:(BOOL)inFlag
{
	if (self = [super initWithFrame:inFrameRect pullsDown:inFlag]) {
		[[self cell] setArrowPosition:NSPopUpNoArrow];
	}
	return self;
}

-(void)awakeFromNib
{
	[[self cell] setArrowPosition:NSPopUpNoArrow];
}

@end

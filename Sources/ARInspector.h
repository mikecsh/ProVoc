//
//  ARInspector.h
//  ARInspector
//
//  Created by Simon Bovet on 06.04.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ARInspector : NSWindowController {
	NSMutableArray *mViews;
	BOOL mOrderingFront;
}

-(void)addView:(NSView *)inView withName:(NSString *)inName identifier:(NSString *)inIdentifier openByDefault:(BOOL)inOpen;

-(BOOL)isVisible;
-(void)toggle;

-(BOOL)isViewVisibleWithIdentifier:(NSString *)inIdentifier;

@end

@interface ARInspectorPanel : NSPanel

@end

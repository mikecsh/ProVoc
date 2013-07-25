//
//  ProVocImageView.m
//  ProVoc
//
//  Created by Simon Bovet on 09.04.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ProVocImageView.h"


@implementation ProVocImageView

-(BOOL)acceptsFirstMouse:(NSEvent *)inEvent
{
	return YES;
}

-(IBAction)displayFullImage:(id)inSender
{
	[[self image] displayInFullSize];
}

-(void)mouseDown:(NSEvent *)inEvent
{
	if ([inEvent clickCount] == 2 && NSPointInRect([self convertPoint:[inEvent locationInWindow] fromView:nil], [self bounds]))
		[self displayFullImage:nil];
}

-(void)insertText:(NSString *)inString
{
	if ([inString isEqual:@" "])
		[self displayFullImage:nil];
}

-(void)insertNewline:(id)inSender
{
	if ([self tag] == 314)
		[super keyDown:[NSApp currentEvent]];
	else
		[self displayFullImage:nil];
}

-(void)delete:(id)inSender
{
	SEL selector = @selector(removeImage:);
	if ([mDelegate respondsToSelector:selector])
		[mDelegate performSelector:selector withObject:nil];
}

-(void)deleteBackward:(id)inSender
{
	[self delete:inSender];
}

-(void)doCommandBySelector:(SEL)inSelector
{
//	NSLog(@"%@@selector(%@)", NSStringFromClass([self class]), NSStringFromSelector(inSelector));
	if ([self respondsToSelector:inSelector])
		[self performSelector:inSelector withObject:nil];
	else
		[super doCommandBySelector:inSelector];
}

-(void)keyDown:(NSEvent *)inEvent
{
	[self interpretKeyEvents:@[inEvent]];
}

-(void)concludeDragOperation:(id <NSDraggingInfo>)inSender
{
	BOOL concluded = NO;
	if ([mDelegate respondsToSelector:@selector(imageView:didReceiveDraggedImageFile:)]) {

		NSArray *fileTypes = [NSImage imageUnfilteredFileTypes];
		NSEnumerator *enumerator = [[[inSender draggingPasteboard] propertyListForType:NSFilenamesPboardType] reverseObjectEnumerator];
		NSString *fileName;
		while (fileName = [enumerator nextObject])
			if ([fileTypes containsObject:[fileName pathExtension]]) {
				[mDelegate imageView:self didReceiveDraggedImageFile:fileName];
				concluded = YES;
				break;
			}
	}
	if (!concluded)
		[super concludeDragOperation:inSender];
}

@end

@implementation NSScreen (FullScreen)

+(NSRect)totalFrame
{
	NSRect frame = NSZeroRect;
	NSEnumerator *enumerator = [[NSScreen screens] objectEnumerator];
	NSScreen *screen;
	while (screen = [enumerator nextObject])
		frame = NSUnionRect(frame, [screen frame]);
	return frame;
}

@end

@implementation NSImage (ProVocImageView)

-(NSSize)pixelSize // ++++ 4.2.2 ++++
{
	NSImageRep *imageRep = [[self representations] lastObject];
	if (imageRep)
		return NSMakeSize([imageRep pixelsWide], [imageRep pixelsHigh]);
	else
		return [self size];
}

-(void)displayInFullSize
{
	NSSize maxSize = [[NSScreen mainScreen] frame].size;
	maxSize.width -= 50;
	maxSize.height -= 50;
	NSSize imageSize = [self pixelSize]; // ++++ 4.2.2 ++++
	[self setSize:imageSize]; // ++++ 4.2.2 ++++
	NSRect contentRect = NSZeroRect;
	float k = MIN(1, MIN(maxSize.width / imageSize.width, maxSize.height / imageSize.height));
	contentRect.size.width = MIN(imageSize.width * k, maxSize.width);
	contentRect.size.height = round(contentRect.size.width / imageSize.width * imageSize.height);
	NSWindow *background = [[NSWindow alloc] initWithContentRect:[NSScreen totalFrame] styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
	[background setOpaque:NO];
	[background setBackgroundColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
	[background setLevel:NSModalPanelWindowLevel];
	[background orderFront:nil];
	NSWindow *window = [[NSWindow alloc] initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
	NSImageView *imageView = [[[NSImageView alloc] initWithFrame:NSZeroRect] autorelease];
	[window setOpaque:NO];
	[window setBackgroundColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.0]];
	[imageView setImageScaling:NSScaleProportionally];
	[window setContentView:imageView];
	[window setLevel:NSModalPanelWindowLevel];
	[imageView setImage:self];
	[window center];
	[window setHasShadow:YES];
	[window makeKeyAndOrderFront:nil];
	[window nextEventMatchingMask:NSLeftMouseDownMask | NSRightMouseDownMask | NSKeyDownMask];
	[window setContentView:nil];
	[window close];
	[background close];
}

@end

//
//  ProVocTableView.m
//  ProVoc
//
//  Created by Simon Bovet on Mon Apr 28 2003.
//  Copyright (c) 2003 Arizona Software. All rights reserved.
//

#import "ProVocTableView.h"
#import "ProVocDocument.h"
#import "SpeechSynthesizerExtensions.h"

@implementation ProVocDeletableTableView

-(void)delete:(id)inSender
{
    if ([self numberOfSelectedRows] > 0 && [[self dataSource] respondsToSelector:@selector(deleteSelectedRowsInTableView:)])
        [[self dataSource] deleteSelectedRowsInTableView:self];
}

-(void)keyDown:(NSEvent *)inEvent
{
    NSString *keyString = [inEvent charactersIgnoringModifiers];
    unichar keyChar = [keyString characterAtIndex:0];

    switch (keyChar) {
        case 0177: // Delete Key
        case NSDeleteFunctionKey:
        case NSDeleteCharFunctionKey:
            [self delete:nil];
            break;
        default:
            [super keyDown:inEvent];
    }
}

@end

@implementation ProVocTableView

-(void)copy:(id)inSender
{
    if ([self numberOfSelectedRows] > 0 && [[self dataSource] respondsToSelector:@selector(tableView:writeRows:toPasteboard:)])
		[[self dataSource] tableView:self writeRows:[[self selectedRowEnumerator] allObjects] toPasteboard:[NSPasteboard generalPasteboard]];
}

-(void)paste:(id)inSender
{
	if ([[self dataSource] respondsToSelector:@selector(tableView:pasteFromPasteboard:)])
		[[self dataSource] tableView:self pasteFromPasteboard:[NSPasteboard generalPasteboard]];
}

-(void)cut:(id)inSender
{
	[self copy:inSender];
	[self delete:inSender];
}

-(void)selectNone:(id)inSender
{
	[self selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
} 

-(NSImage *)tableView:(NSTableView *)inTableView dragImageBadgeForRowIndexes:(NSIndexSet *)inIndexSet
{
	return nil;
}

-(NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)inDragRows tableColumns:(NSArray *)inTableColumns event:(NSEvent*)inDragEvent offset:(NSPointPointer)inDragImageOffset
{
	NSImage *image = [super dragImageForRowsWithIndexes:inDragRows tableColumns:inTableColumns event:inDragEvent offset:inDragImageOffset];
	NSImage *badge = [[self dataSource] tableView:self dragImageBadgeForRowIndexes:inDragRows];
	if (!badge)
		return image;
	NSSize margin = [badge size];
	NSSize newSize = [image size];
	newSize.width += 2 * margin.width;
	newSize.height += 2 * margin.height;
	NSImage *newImage = [[[NSImage alloc] initWithSize:newSize] autorelease];
	[newImage lockFocus];
	[image dissolveToPoint:NSMakePoint(margin.width, margin.height) fraction:1.0];
	NSPoint pt = NSMakePoint(0.5 * newSize.width - inDragImageOffset->x, 0.5 * newSize.height - inDragImageOffset->y);
	[badge dissolveToPoint:pt fraction:1.0];
	[newImage unlockFocus];
	return newImage;
}

-(NSMenu *)tableView:(NSTableView *)inTableView menuForEvent:(NSEvent *)inEvent
{
	return nil;
}

-(NSMenu *)menuForEvent:(NSEvent *)inEvent
{
	if ([[self delegate] respondsToSelector:@selector(tableView:menuForEvent:)])
		return [[self delegate] tableView:self menuForEvent:inEvent];
	else
		return [super menuForEvent:inEvent];
}

-(NSSpeechSynthesizer *)speechSynthesizer
{
	return [NSSpeechSynthesizer commonSpeechSynthesizer];
}

-(NSArray *)speakableIdentifiers
{
	NSMutableArray *speakableIdentifiers = [NSMutableArray array];
	id dataSource = [self dataSource];
	if ([[dataSource sourceLanguage] isEqual:@"English"])
		[speakableIdentifiers addObject:@"Source"];
	if ([[dataSource targetLanguage] isEqual:@"English"])
		[speakableIdentifiers addObject:@"Target"];
	return speakableIdentifiers;
}

-(BOOL)canStartSpeaking
{
	return [[self selectedRowIndexes] count] > 0 && [[self speakableIdentifiers] count] > 0;
}

-(void)startSpeaking:(id)inSender
{
	NSArray *allowedIdentifiers = [self speakableIdentifiers];
	NSMutableArray *columns = [NSMutableArray array];
	NSEnumerator *enumerator = [[self tableColumns] objectEnumerator];
	NSTableColumn *column;
	while (column = [enumerator nextObject])
		if ([allowedIdentifiers containsObject:[column identifier]])
			[columns addObject:column];
	columns = [[columns copy] autorelease];
	
	id dataSource = [self dataSource];
	NSMutableString *text = [NSMutableString string];
	NSEnumerator *rowEnumerator = [self selectedRowEnumerator];
	id row;
	while (row = [rowEnumerator nextObject]) {
		int rowIndex = [row intValue];
		NSEnumerator *enumerator = [columns objectEnumerator];
		id column;
		while (column = [enumerator nextObject]) {
			id string = [dataSource tableView:self objectValueForTableColumn:column row:rowIndex];
			if ([string length] > 0)
				[text appendFormat:@"%@, ", string];
		}
	}
	
	[[self speechSynthesizer] stopSpeaking]; // ++++ v4.2.2 ++++
	[[self speechSynthesizer] startSpeakingString:text];
}

-(void)stopSpeaking:(id)inSender
{
	[[self speechSynthesizer] stopSpeaking];
}

-(BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL selector = [inMenuItem action];
	if (selector == @selector(startSpeaking:))
		return [self canStartSpeaking];
	if (selector == @selector(stopSpeaking:))
		return [[self speechSynthesizer] isSpeaking];
	if (selector == @selector(copy:) || selector == @selector(cut:) || selector == @selector(delete:))
		return [self numberOfSelectedRows] > 0;
	else if (selector == @selector(paste:) && [[self dataSource] respondsToSelector:@selector(tableView:canPasteFromPasteboard:)])
		return [[self dataSource] tableView:self canPasteFromPasteboard:[NSPasteboard generalPasteboard]];
	else
		return YES;
}

@end

@implementation ProVocOutlineView

-(BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL selector = [inMenuItem action];
	if (selector == @selector(copy:) || selector == @selector(cut:) || selector == @selector(delete:))
		return [self numberOfSelectedRows] > 0;
	else if (selector == @selector(paste:) && [[self dataSource] respondsToSelector:@selector(outlineView:canPasteFromPasteboard:)])
		return [[self dataSource] outlineView:self canPasteFromPasteboard:[NSPasteboard generalPasteboard]];
	else
		return YES;
}

-(void)copy:(id)inSender
{
    if ([self numberOfSelectedRows] > 0 && [[self dataSource] respondsToSelector:@selector(outlineView:writeItems:toPasteboard:)]) {
		NSMutableArray *items = [NSMutableArray array];
		NSEnumerator *enumerator = [self selectedRowEnumerator];
		NSNumber *row;
		while (row = [enumerator nextObject])
			[items addObject:[self itemAtRow:[row intValue]]];
		[[self dataSource] outlineView:self writeItems:items toPasteboard:[NSPasteboard generalPasteboard]];
	}
}

-(void)paste:(id)inSender
{
	if ([[self dataSource] respondsToSelector:@selector(outlineView:pasteFromPasteboard:)])
		[[self dataSource] outlineView:self pasteFromPasteboard:[NSPasteboard generalPasteboard]];
}

-(void)delete:(id)inSender
{
    if ([self numberOfSelectedRows] > 0 && [[self dataSource] respondsToSelector:@selector(deleteSelectedRowsInOutlineView:)])
        [[self dataSource] deleteSelectedRowsInOutlineView:self];
}

-(void)cut:(id)inSender
{
	[self copy:inSender];
	[self delete:inSender];
}

-(void)keyDown:(NSEvent *)inEvent
{
    NSString *keyString = [inEvent charactersIgnoringModifiers];
    unichar keyChar = [keyString characterAtIndex:0];

    switch (keyChar) {
        case 0177: // Delete Key
        case NSDeleteFunctionKey:
        case NSDeleteCharFunctionKey:
            [self delete:nil];
            break;
        default:
            [super keyDown:inEvent];
    }
} 

@end

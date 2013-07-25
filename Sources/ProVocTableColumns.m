//
//  ProVocTableColumns.m
//  ProVoc
//
//  Created by Simon Bovet on Mon Apr 28 2003.
//  Copyright (c) 2003 Arizona Software. All rights reserved.
//

#import "ProVocTableColumns.h"

#import "ExtendedCell.h"
#import "MenuExtensions.h"

@interface NSObject (DifficultyTableDataSource)

-(BOOL)displayExtraRowInTableView:(NSTableView *)inTableView;

@end

@implementation ProVocDifficultyTableColumn

-(id)dataCellForRow:(int)inRow
{
	if (!mDataCell)
		mDataCell = [[RankCell alloc] init];
    if (inRow >= 0 && inRow < [[self tableView] numberOfRows] - ([[[self tableView] dataSource] displayExtraRowInTableView:[self tableView]] ? 1 : 0))
        return mDataCell;
    else
        return [super dataCellForRow:inRow];
}

-(void)dealloc
{
	[mDataCell release];
	[super dealloc];
}

@end

@implementation ProVocFlaggedTableColumn

-(id)dataCellForRow:(int)inRow
{
	if (!mDataCell)
		mDataCell = [[NSImageCell alloc] init];
	return mDataCell;
}

-(void)dealloc
{
	[mDataCell release];
	[super dealloc];
}

@end

@implementation ProVocPresetTableColumn

-(id)dataCellForRow:(int)inRow
{
	if (!mDataCell) {
		mDataCell = [[PresetCell alloc] init];
		[(PresetCell *)mDataCell setDelegate:[[self tableView] dataSource]];
	}
	return mDataCell;
}

-(void)dealloc
{
	[mDataCell release];
	[super dealloc];
}

@end

@implementation ProVocWordTableColumn

-(id)dataCell
{
	if (!mDataCell) {
		mDataCell = [[FlaggedTextCell alloc] init];
		[mDataCell setEditable:YES];
	}
	return mDataCell;
}

-(void)dealloc
{
	[mDataCell release];
	[super dealloc];
}

@end

@implementation ProVocTableHeaderView

-(id)initWithFrame:(NSRect)inFrame
{
	if (self = [super initWithFrame:inFrame]) {
		mMenu = [[NSMenu alloc] initWithTitle:@""];
		[mMenu addItemWithTitle:NSLocalizedString(@"Auto Size Column", @"") target:self selector:@selector(autoSizeColumn:)];
		[mMenu addItemWithTitle:NSLocalizedString(@"Auto Size All Columns", @"") target:self selector:@selector(autoSizeAllColumns:)];
		[mMenu addItem:[NSMenuItem separatorItem]];
		[mMenu addItemWithTitle:NSLocalizedString(@"Delete Column Contents", @"") target:self selector:@selector(deleteColumnContents:)];
	}
	return self;
}

-(void)dealloc
{
	[mMenu release];
	[super dealloc];
}

-(void)setDelegate:(id)inDelegate
{
	mDelegate = inDelegate;
}

-(NSMenu *)menu
{
	return mMenu;
}

-(NSMenu *)menuForEvent:(NSEvent *)inEvent
{
	NSPoint point = [[self tableView] convertPoint:[inEvent locationInWindow] fromView:nil];
	point.y = 0;
	mCurrentColumnIndex = [[self tableView] columnAtPoint:point];
	return [super menuForEvent:inEvent];
}

-(void)autoSizeColumn:(id)inSender
{
	if (mCurrentColumnIndex >= 0)
		[mDelegate tableView:[self tableView] autoSizeTableColumn:[[self tableView] tableColumns][mCurrentColumnIndex]];
}

-(void)deleteColumnContents:(id)inSender
{
	if (mCurrentColumnIndex >= 0)
		[mDelegate tableView:[self tableView] deleteContentsOfTableColumn:[[self tableView] tableColumns][mCurrentColumnIndex]];
}

-(void)autoSizeAllColumns:(id)inSender
{
	NSEnumerator *enumerator = [[[self tableView] tableColumns] objectEnumerator];
	NSTableColumn *tableColumn;
	while (tableColumn = [enumerator nextObject])
		[mDelegate tableView:[self tableView] autoSizeTableColumn:tableColumn];
}

@end

@implementation NSObject (AutoSizeColumns)

-(void)tableView:(NSTableView *)inTableView autoSizeTableColumn:(NSTableColumn *)inTableColumn
{
}

-(void)tableHeaderView:(NSTableHeaderView *)inHeaderView appendItemsToMenu:(NSMenu *)inMenu
{
}

-(void)tableView:(NSTableView *)inTableView deleteContentsOfTableColumn:(NSTableColumn *)inTableColumn
{
}

@end
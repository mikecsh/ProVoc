//
//  TableViewExtensions.m
//  ProVoc
//
//  Created by Simon Bovet on Tue May 06 2003.
//  Copyright (c) 2003 Arizona Software. All rights reserved.
//

#import "TableViewExtensions.h"


@interface NSTableView ( Private )
// Declarations of 10.1 private methods, just to make the compiler happy.
+ (id) _defaultTableHeaderReverseSortImage;
+ (id) _defaultTableHeaderSortImage;
@end

@implementation NSTableView (ProVocExtensions)

+ (NSImage *) ascendingSortIndicator
{
	NSImage *result = [NSImage imageNamed:@"NSAscendingSortIndicator"];
	if (nil == result && [[NSTableView class] respondsToSelector:@selector(_defaultTableHeaderSortImage)])
	{
		result = [NSTableView _defaultTableHeaderSortImage];
	}
	return result;
}

/*"	Return the sorting indicator image; works on 10.1 and 10.2.
"*/

+ (NSImage *) descendingSortIndicator
{
	NSImage *result = [NSImage imageNamed:@"NSDescendingSortIndicator"];
	if (nil == result && [[NSTableView class] respondsToSelector:@selector(_defaultTableHeaderReverseSortImage)])
	{
		result = [NSTableView _defaultTableHeaderReverseSortImage];
	}
	return result;
}

-(id)tableColumnStates
{
	NSMutableArray *states = [NSMutableArray array];
	NSEnumerator *enumerator = [[self tableColumns] objectEnumerator];
	NSTableColumn *column;
	while (column = [enumerator nextObject]) {
		id identifier = [column identifier];
		id width = [NSNumber numberWithFloat:[column width]];
		NSDictionary *state = @{@"Identifier": identifier, @"Width": width};
		[states addObject:state];
	}
	return @{@"Version": @1, @"States": states};
}

-(void)setTableColumnStates:(id)inStates
{
	int version = 0;
	NSArray *states = inStates;
	if ([inStates isKindOfClass:[NSDictionary class]]) {
		version = [inStates[@"Version"] intValue];
		states = inStates[@"States"];
	}
	
	NSEnumerator *enumerator = [states objectEnumerator];
	NSDictionary *state;
	NSMutableArray *identifiers = [NSMutableArray array];
	while (state = [enumerator nextObject])
		[identifiers addObject:state[@"Identifier"]];
	
	if (version >= 1) {
		enumerator = [[self tableColumns] reverseObjectEnumerator];
		NSTableColumn *tableColumn;
		while (tableColumn = [enumerator nextObject])
			if (![identifiers containsObject:[tableColumn identifier]])
				[self removeTableColumn:tableColumn];
	}
	
	enumerator = [states objectEnumerator];
	int index = 0;
	while (state = [enumerator nextObject]) {
		NSTableColumn *column = [self tableColumnWithIdentifier:state[@"Identifier"]];
		if (column) {
			[self moveColumn:[[self tableColumns] indexOfObjectIdenticalTo:column] toColumn:index];
			[column setWidth:[state[@"Width"] floatValue]];
		}
		index++;
	}
}

@end

@implementation NSOutlineView (ExpandedState)

-(id)expandedStateOfItem:(id)inItem
{
    id dataSource = [self dataSource];
    NSMutableArray *array = [NSMutableArray array];
    int i, n = [dataSource outlineView:self numberOfChildrenOfItem:inItem];
    for (i = 0; i < n; i++) {
        id item = [dataSource outlineView:self child:i ofItem:inItem];
        BOOL expanded = [self isItemExpanded:item];
        [array addObject:@(expanded)];
        if (!expanded)
            [self expandItem:item];
        [array addObject:[self expandedStateOfItem:item]];
        if (!expanded)
            [self collapseItem:item];
    }
    return array;
}

-(id)expandedState
{
    return [self expandedStateOfItem:nil];
}

-(void)setExpandedState:(id)inState ofItem:(id)inItem
{
    id dataSource = [self dataSource];
    int i, n = [dataSource outlineView:self numberOfChildrenOfItem:inItem];
    NSEnumerator *enumerator = [inState objectEnumerator];
    id state;
    for (i = 0; i < n; i++) {
        id item = [dataSource outlineView:self child:i ofItem:inItem];
        BOOL expanded = [(state = [enumerator nextObject]) boolValue];
        [self expandItem:item];
        [self setExpandedState:[enumerator nextObject] ofItem:item];
        if (!expanded)
            [self collapseItem:item];
    }
}

-(void)setExpandedState:(id)inState
{
    [self setExpandedState:inState ofItem:nil];
}

@end

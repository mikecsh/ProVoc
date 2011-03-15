//
//  ProVocDocument+Lists.m
//  ProVoc
//
//  Created by Simon Bovet on 31.10.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import "ProVocDocument+Lists.h"
#import "ProVocDocument+Export.h"
#import "ProVocDocument+Presets.h"
#import "ProVocChapter.h"
#import "ProVocData.h"
#import "ProVocPreferences.h"
#import "ProVocSilentTester.h"
#import "ProVocTableColumns.h"
#import "ProVocInspector.h"

#import "TableViewExtensions.h"
#import "BezierPathExtensions.h"
#import "StringExtensions.h"
#import "ImageExtensions.h"
#import "ExtendedCell.h"

#import <QTKit/QTKit.h>

static NSArray *sDraggedItems = nil;

@interface ProVocLabel : NSObject {
	ProVocDocument *mDocument;
	int mIndex;
}

-(id)initWithDocument:(ProVocDocument *)inDocument index:(int)inIndex;

@end

@implementation ProVocDocument (DataSource)

-(id)itemForOutlineView:(NSOutlineView *)inOutlineView item:(id)inItem
{
	if (inOutlineView == mPageOutlineView)
		return inItem ? inItem : [mProVocData rootChapter];
	else
		return nil;
}

-(int)outlineView:(NSOutlineView *)inOutlineView numberOfChildrenOfItem:(id)inItem
{
	id item = [self itemForOutlineView:inOutlineView item:inItem];
	if ([item respondsToSelector:@selector(children)])
		return [[item children] count];
	else
		return 0;
}

-(BOOL)outlineView:(NSOutlineView *)inOutlineView isItemExpandable:(id)inItem
{
	id item = [self itemForOutlineView:inOutlineView item:inItem];
	return [item respondsToSelector:@selector(children)];
}

-(id)outlineView:(NSOutlineView *)inOutlineView child:(int)inIndex ofItem:(id)inItem
{
	id item = [self itemForOutlineView:inOutlineView item:inItem];
	if ([item respondsToSelector:@selector(children)])
		return [[item children] objectAtIndex:inIndex];
	else
		return nil;
}

-(id)outlineView:(NSOutlineView *)inOutlineView objectValueForTableColumn:(NSTableColumn *)inTableColumn byItem:(id)inItem
{
	id item = [self itemForOutlineView:inOutlineView item:inItem];
	return [item title];
}

-(void)outlineView:(NSOutlineView *)inOutlineView setObjectValue:(id)inObject forTableColumn:(NSTableColumn *)inTableColumn byItem:(id)inItem
{
	id item = [self itemForOutlineView:inOutlineView item:inItem];
	[self willChangeSource:item];
	[item setTitle:inObject];
	[self didChangeSource:item];
}

-(void)outlineViewSelectionDidChange:(NSNotification *)inNotification
{
	[self selectedPagesDidChange];
}

-(void)setWords:(NSArray *)inWords inPasteboard:(NSPasteboard *)inPasteboard
{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	[dictionary setObject:inWords forKey:@"Words"];
	NSString *mediaPath = [self mediaPathInBundle];
	if (mediaPath)
		[dictionary setObject:mediaPath forKey:@"MediaPath"];
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
	[inPasteboard setData:data forType:ProVocWordsType];
}

-(NSArray *)wordsFromPasteboard:(NSPasteboard *)inPasteboard
{
	NSData *data = [inPasteboard dataForType:ProVocWordsType];
	if (!data)
		return nil;
	
	NSDictionary *dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	NSString *mediaPath = [dictionary objectForKey:@"MediaPath"];
	NSArray *words = [dictionary objectForKey:@"Words"];
	[words makeObjectsPerformSelector:@selector(resetIndexInFile)];
	if (![mediaPath isEqual:[self mediaPathInBundle]] && mediaPath != [self mediaPathInBundle]) {
		NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:self, @"Document", mediaPath, @"MediaPath", nil];
		[words makeObjectsPerformSelector:@selector(reimportMediaFrom:) withObject:info];
	}
	return words;
}

-(void)setSources:(NSArray *)inSources inPasteboard:(NSPasteboard *)inPasteboard
{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	[dictionary setObject:inSources forKey:@"Sources"];
	NSString *mediaPath = [self mediaPathInBundle];
	if (mediaPath)
		[dictionary setObject:mediaPath forKey:@"MediaPath"];
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
	[inPasteboard setData:data forType:ProVocSourcesType];
}

-(NSArray *)sourcesFromPasteboard:(NSPasteboard *)inPasteboard
{
	NSData *data = [inPasteboard dataForType:ProVocSourcesType];
	if (!data)
		return nil;
	
	NSDictionary *dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	NSString *mediaPath = [dictionary objectForKey:@"MediaPath"];
	NSArray *sources = [dictionary objectForKey:@"Sources"];
	if (![mediaPath isEqual:[self mediaPathInBundle]] && mediaPath != [self mediaPathInBundle]) {
		NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:self, @"Document", mediaPath, @"MediaPath", nil];
		[sources makeObjectsPerformSelector:@selector(reimportMediaFrom:) withObject:info];
	}
	return sources;
}

-(void)pasteboard:(NSPasteboard *)inPasteboard provideDataForType:(NSString *)inType
{
	if ([inType isEqual:NSStringPboardType])
		[inPasteboard setString:[self stringFromPages:[self selectedPages]] forType:NSStringPboardType];
}

-(BOOL)outlineView:(NSOutlineView *)inOutlineView writeItems:(NSArray *)inItems toPasteboard:(NSPasteboard *)inPasteboard
{
	NSArray *items = [inItems commonAncestors];
	[sDraggedItems release];
	sDraggedItems = [items retain];
		
	[inPasteboard declareTypes:[NSArray arrayWithObjects:ProVocSelfSourcesType, ProVocSourcesType, NSStringPboardType, nil] owner:self];
	[self setSources:items inPasteboard:inPasteboard];
	return YES;
}

-(NSDragOperation)outlineView:(NSOutlineView *)inOutlineView validateDrop:(id <NSDraggingInfo>)inInfo proposedItem:(id)inItem proposedChildIndex:(int)inIndex
{
    NSDragOperation operation = [inInfo draggingSourceOperationMask];
	operation = operation == NSDragOperationCopy ? NSDragOperationCopy : NSDragOperationMove;
	
    if ([[inInfo draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:ProVocSelfSourcesType]]) {
		if (operation != NSDragOperationCopy && [sDraggedItems containsDescendant:inItem])
			return NSDragOperationNone;
		if (inIndex < 0 && ![inItem isKindOfClass:[ProVocChapter class]])
			return NSDragOperationNone;
		return operation;
	}
    if ([[inInfo draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:ProVocSourcesType]]) {
		if (inIndex < 0 && ![inItem isKindOfClass:[ProVocChapter class]])
			return NSDragOperationNone;
		return NSDragOperationCopy;
	}
	
    if ([[inInfo draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:ProVocSelfWordsType, ProVocWordsType, nil]]) {
		if (inIndex < 0 && !inItem)
			return operation;
		if (inIndex >= 0 || ![inItem isKindOfClass:[ProVocPage class]])
			return NSDragOperationNone;
		return operation;
	}
	
	return NSDragOperationNone;
}

-(BOOL)outlineView:(NSOutlineView *)inOutlineView canPasteFromPasteboard:(NSPasteboard *)inPasteboard
{
    if ([inPasteboard availableTypeFromArray:[NSArray arrayWithObject:ProVocWordsType]] && [mSelectedPages count] == 1)
		return YES;
	
    if ([inPasteboard availableTypeFromArray:[NSArray arrayWithObject:ProVocSourcesType]])
		return YES;
		
	return NO;
}

-(void)insertChildren:(NSArray *)inChildren item:(id)inItem atIndex:(int)inIndex
{
	[self willChangeData];
	[inItem insertChildren:inChildren atIndex:inIndex];
	[self pagesDidChange];

	NSEnumerator *enumerator = [inChildren objectEnumerator];
	BOOL extend = NO;
	id item;
	int row = -1;
	while (item = [enumerator nextObject]) {
		[mPageOutlineView selectRow:row = [mPageOutlineView rowForItem:item] byExtendingSelection:extend];
		extend = YES;
	}
	[mPageOutlineView scrollRowToVisible:row];
	[self didChangeData];
}

-(BOOL)outlineView:(NSOutlineView *)inOutlineView acceptDrop:(id <NSDraggingInfo>)inInfo item:(id)inItem childIndex:(int)inIndex
{
	id draggedItems = [sDraggedItems autorelease];
	sDraggedItems = nil;
	BOOL copy = [inInfo draggingSourceOperationMask] == NSDragOperationCopy;
	BOOL ok = NO;
	BOOL removeFromParents = NO;

	if ([[inInfo draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:ProVocSourcesType, ProVocSelfSourcesType, nil]]) {
		id item = inItem ? inItem : [mProVocData rootChapter];
		int index = inIndex >= 0 ? inIndex : [[item children] count];
		
		if (!copy && [[inInfo draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:ProVocSelfSourcesType]]) {
			NSEnumerator *enumerator = [draggedItems reverseObjectEnumerator];
			ProVocSource *draggedItem;
			while (draggedItem = [enumerator nextObject])
				if ([draggedItem parent] == item && [[[draggedItem parent] children] indexOfObjectIdenticalTo:draggedItem] <= index)
					index--;
			removeFromParents = YES;
			ok = YES;
		} else {
			draggedItems = [self sourcesFromPasteboard:[inInfo draggingPasteboard]];
			if (draggedItems)
				ok = YES;
		}
		
		if (ok) {
			[self willChangeData];
			if (removeFromParents)
				[draggedItems makeObjectsPerformSelector:@selector(removeFromParent)];
			[self insertChildren:draggedItems item:item atIndex:index];
			[self didChangeData];
		}
	} else {
		ProVocPage *page = (ProVocPage *)inItem;
		if (!copy && [[inInfo draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:ProVocSelfWordsType]]) {
			NSMutableArray *draggedWords = [NSMutableArray array];
			NSEnumerator *enumerator = [draggedItems objectEnumerator];
			ProVocWord *word;
			while (word = [enumerator nextObject])
				if (![[page words] containsObject:word])
					[draggedWords addObject:word];
			removeFromParents = YES;
			draggedItems = draggedWords;
			ok = YES;
		} else {
			draggedItems = [self wordsFromPasteboard:[inInfo draggingPasteboard]];
			if (draggedItems)
				ok = YES;
		}

		if (ok) {
			[self willChangeData];
			if (removeFromParents)
				[draggedItems makeObjectsPerformSelector:@selector(removeFromParent)];
			if (!page) {
				page = [[[ProVocPage alloc] init] autorelease];
				NSString *title = [[draggedItems objectAtIndex:0] sourceWord];
				[page setTitle:[NSString stringWithFormat:@"%@...", title]];

				ProVocChapter *chapter = [mProVocData rootChapter];
				[chapter insertChild:page atIndex:[[chapter children] count]];
				[self pagesDidChange];
				[mPageOutlineView expandItem:page];
				int row = [mPageOutlineView rowForItem:page];
				[mPageOutlineView selectRow:row byExtendingSelection:NO];
				[mPageOutlineView scrollRowToVisible:row];
			}
			[page addWords:draggedItems];
			[self selectedPagesDidChange];
			[self didChangeData];
		}
	}
	return ok;
}

-(void)outlineView:(NSOutlineView *)inOutlineView pasteFromPasteboard:(NSPasteboard *)inPasteboard
{
    if ([inPasteboard availableTypeFromArray:[NSArray arrayWithObject:ProVocWordsType]]) {
		NSArray *words = [self wordsFromPasteboard:inPasteboard];
		if (words) {
			ProVocPage *page = [self currentPage];
			[self willChangeSource:page];
			[page addWords:words];
			[self selectedPagesDidChange];
			[self didChangeSource:page];
			return;
		}
	}
	
    if ([inPasteboard availableTypeFromArray:[NSArray arrayWithObject:ProVocSourcesType]]) {
		id item = [inOutlineView itemAtRow:[inOutlineView selectedRow]];
		if (!item)
			item = [mProVocData rootChapter];
		int index;
		if ([item isKindOfClass:[ProVocChapter class]])
			index = [[item children] count];
		else {
			index = [[[item parent] children] indexOfObjectIdenticalTo:item] + 1;
			item = [item parent];
		}
		NSArray *children = [self sourcesFromPasteboard:inPasteboard];
		if (children)
			[self insertChildren:children item:item atIndex:index];
	}
}

-(void)deleteSelectedRowsInOutlineView:(NSOutlineView *)inOutlineView
{
	[self deletePage:nil];
}

-(BOOL)outlineView:(NSOutlineView *)inOutlineView shouldSelectItem:(id)inItem
{
	[self keepSelectedWords];
	return YES;
}

#pragma mark -

-(BOOL)displayExtraRowInTableView:(NSTableView *)inTableView
{
	return [self showingAllWords] && [self canAddWord];
}

-(int)numberOfRowsInTableView:(NSTableView *)inTableView
{
	if (inTableView == mPresetTableView)
		return [[self presets] count];
	else
		return [mVisibleWords count] + ([self displayExtraRowInTableView:inTableView] ? 1 : 0);
}

-(id)tableView:(NSTableView *)inTableView objectValueForTableColumn:(NSTableColumn *)inTableColumn row:(int)inRowIndex
{
	if (inTableView == mPresetTableView)
		return [[self presets] objectAtIndex:inRowIndex];
	if (inRowIndex >= [mVisibleWords count])
		return nil;
	ProVocWord *word = [mVisibleWords objectAtIndex:inRowIndex];
	if ([[inTableColumn identifier] isEqual:@"Difficulty"])
		return [NSNumber numberWithFloat:([word difficulty] - mMinDifficulty) / (mMaxDifficulty - mMinDifficulty)];
	else
		return [word objectForIdentifier:[inTableColumn identifier]];
}

-(void)tableView:(NSTableView *)inTableView setObjectValue:(id)inObject forTableColumn:(NSTableColumn *)inTableColumn row:(int)inRowIndex
{
	if (inTableView == mPresetTableView)
		return;
	if (inRowIndex < [mVisibleWords count]) {
		ProVocWord *word = [mVisibleWords objectAtIndex:inRowIndex];
		id object = inObject;
		if ([inObject isKindOfClass:[NSAttributedString class]])
			object = [inObject string];
		if (![[word objectForIdentifier:[inTableColumn identifier]] isEqual:object]) {
			[self willChangeWord:word];
			[word setObject:object forIdentifier:[inTableColumn identifier]];
			[self didChangeWord:word];
			[self selectedWordsDidChange:nil];
		}
	} else {
		if ([(NSString *)inObject length] == 0)
			return;
			
		ProVocWord *word = [[[ProVocWord alloc] init] autorelease];
		[word setObject:inObject forIdentifier:[inTableColumn identifier]];
		ProVocPage *page = [self currentPage];
		[self willChangeSource:page];
		[page addWord:word];
		[self wordsDidChange];
		[self didChangeSource:page];
	}
}

-(BOOL)tableView:(NSTableView *)inTableView shouldEditTableColumn:(NSTableColumn *)inTableColumn row:(int)inRowIndex
{
	if (inTableView == mPresetTableView) {
		[self setEditingPreset:!mEditingPreset];
		return NO;
	}
    if (inTableView == mWordTableView && [[inTableColumn identifier] isEqualTo:@"Mark"]) {
		NSEvent *event = [NSApp currentEvent];
        if ([event type] == NSLeftMouseDown && [event clickCount] > 1 && inRowIndex < [mVisibleWords count]) {
			ProVocWord *word = [mVisibleWords objectAtIndex:inRowIndex];
			[self willChangeWord:word];
			[word setMark:1 - [word mark]];
			[inTableView reloadData];
			[self didChangeWord:word];
		}
        return NO;
    }
	if ([[NSApp currentEvent] type] == NSLeftMouseDown && inTableView == mWordTableView && inRowIndex < [mVisibleWords count]) {
		NSRect rect = [mWordTableView frameOfCellAtColumn:[[mWordTableView tableColumns] indexOfObject:inTableColumn] row:inRowIndex];
		NSPoint pt = [mWordTableView convertPoint:[[NSApp currentEvent] locationInWindow] fromView:nil];
		ProVocWord *word = [mVisibleWords objectAtIndex:inRowIndex];
		if ([[inTableColumn identifier] isEqual:@"Number"]) {
			[self displayMediaOfWord:word];
			return NO;
		} else if ([word canPlayAudio:[inTableColumn identifier]] && pt.x < NSMinX(rect) + [[NSImage imageNamed:@"SmallSpeaker"] size].width + 4 && pt.x > NSMinX(rect)) {
			[self playAudio:[inTableColumn identifier] ofWord:word];
			return NO;
		}
	}
    if (inTableView == mWordTableView && ([[inTableColumn identifier] isEqualTo:@"Difficulty"] || [[inTableColumn identifier] isEqualTo:@"Number"] || [[inTableColumn identifier] isEqualTo:@"LastAnswered"] || [[inTableColumn identifier] isEqualTo:@"NextReview"]))
        return NO;
		
	return YES;
}

-(void)deleteSelectedRowsInTableView:(NSTableView *)inTableView
{
	if (inTableView == mPresetTableView)
		[self removePreset:nil];
	else if (inTableView == mWordTableView) {
		NSArray *selectedWords = [self selectedWords];
		BOOL deselect = [selectedWords count] > 1;
        [self deleteWords:selectedWords];
		if (deselect)
			[mWordTableView deselectAll:nil];
	}
}

-(BOOL)tableView:(NSTableView *)inTableView writeRows:(NSArray *)inRows toPasteboard:(NSPasteboard *)inPasteboard
{
	if (inTableView == mPresetTableView) {
		[inPasteboard declareTypes:[NSArray arrayWithObject:PRESET_PBOARD_TYPE] owner:self];
		[inPasteboard setData:[NSKeyedArchiver archivedDataWithRootObject:inRows] forType:PRESET_PBOARD_TYPE];
		return YES;
	} else if (inTableView == mWordTableView) {
		NSMutableArray *words = [NSMutableArray array];
		NSEnumerator *enumerator = [inRows objectEnumerator];
		NSNumber *row;
		while (row = [enumerator nextObject]) {
			int index = [row intValue];
			if (index < [mVisibleWords count])
				[words addObject:[mVisibleWords objectAtIndex:index]];
		}
		[sDraggedItems release];
		sDraggedItems = [words retain];
		
		[inPasteboard declareTypes:[NSArray arrayWithObjects:ProVocSelfWordsType, ProVocWordsType, NSStringPboardType, nil] owner:self];
		[self setWords:words inPasteboard:inPasteboard];
		[inPasteboard setString:[self stringFromWords:words] forType:NSStringPboardType];

		return YES;
	} else
		return NO;
}

-(NSDragOperation)tableView:(NSTableView *)inTableView validateDrop:(id <NSDraggingInfo>)inInfo proposedRow:(int)inRow proposedDropOperation:(NSTableViewDropOperation)inOperation
{
	if (inTableView == mPresetTableView) {
		if (inOperation == NSTableViewDropOn)
			return NSDragOperationNone;
			
		if ([[inInfo draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:PRESET_PBOARD_TYPE]])
			return NSDragOperationMove;
	} else if (inTableView == mWordTableView) {
		if (inOperation == NSTableViewDropOn && inRow == [mVisibleWords count])
			inOperation = NSTableViewDropAbove;
		if (inOperation != NSTableViewDropOn && inRow <= [mVisibleWords count]) {
			if ([[inInfo draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:ProVocSelfWordsType]])
				return [inInfo draggingSourceOperationMask] == NSDragOperationCopy ? NSDragOperationCopy : NSDragOperationMove;
			if ([[inInfo draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:ProVocWordsType]])
				return NSDragOperationCopy;
		}
			
		NSArray *fileNames;
		if (inOperation == NSTableViewDropOn && inRow < [mVisibleWords count] && (fileNames = [[inInfo draggingPasteboard] propertyListForType:NSFilenamesPboardType])) {
			if ([fileNames count] == 1) {
				NSString *fileType = [[fileNames objectAtIndex:0] pathExtension];
				if ([[NSSound soundUnfilteredFileTypes] containsObject:fileType] || [[NSImage imageUnfilteredFileTypes] containsObject:fileType] || [NSApp hasQTKit] && [[QTMovie movieUnfilteredFileTypes] containsObject:fileType])
					return NSDragOperationCopy;
			}
		}
	}	
	return NSDragOperationNone;
}

-(BOOL)tableView:(NSTableView *)inTableView canPasteFromPasteboard:(NSPasteboard *)inPasteboard
{
	if (inTableView == mWordTableView)
	    return [inPasteboard availableTypeFromArray:[NSArray arrayWithObjects:ProVocWordsType, NSStringPboardType, nil]] != nil;
	else
		return NO;
}

-(void)insertWords:(NSArray *)inWords row:(int)inRow
{
	int index;
	ProVocPage *page;
	if ([mVisibleWords count] == 0) {
		page = [self currentPage];
		index = 0;
	} else {
		int row = inRow;
		BOOL above = YES;
		if (row == [mVisibleWords count]) {
			row--;
			above = NO;
		}
		ProVocWord *word = [mVisibleWords objectAtIndex:row];
		page = [word page];
		index = [[page words] indexOfObjectIdenticalTo:word];
		if (!above)
			index++;
	}

	[self willChangeSource:page];
	[page insertWords:inWords atIndex:index];
	[self selectedPagesDidChange];
	[self didChangeSource:page];

	NSEnumerator *enumerator = [inWords objectEnumerator];
	BOOL extend = NO;
	int row = -1;
	ProVocWord *word;
	while (word = [enumerator nextObject]) {
		[mWordTableView selectRow:row = [mVisibleWords indexOfObjectIdenticalTo:word] byExtendingSelection:extend];
		extend = YES;
	}
	[mWordTableView scrollRowToVisible:row];
}

-(BOOL)tableView:(NSTableView *)inTableView acceptDrop:(id <NSDraggingInfo>)inInfo row:(int)inRow dropOperation:(NSTableViewDropOperation)inOperation
{
	if (inTableView == mPresetTableView) {
		NSData *data = [[inInfo draggingPasteboard] dataForType:PRESET_PBOARD_TYPE];
		if (data) {
			[self willChangePresets];
			NSArray *rows = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			int from = [[rows objectAtIndex:0] intValue];
			int to = inRow;
			if (to > from)
				to--;
			id preset = [[[mPresets objectAtIndex:from] retain] autorelease];
			[mPresets removeObjectAtIndex:from];
			[mPresets insertObject:preset atIndex:to];
			mIndexOfCurrentPresets = to;
			[self presetsDidChange:nil];
			[self didChangePresets];
			return YES;
		} else
			return NO;
	} else if (inTableView == mWordTableView) {
		id draggedWords = [sDraggedItems autorelease];
		sDraggedItems = nil;
		BOOL copy = [inInfo draggingSourceOperationMask] == NSDragOperationCopy;
		BOOL ok = NO;
		BOOL removeFromParents = NO;

		if (!copy && [[inInfo draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:ProVocSelfWordsType]]) {
			removeFromParents = YES;
			ok = YES;
		} else {
			draggedWords = [self wordsFromPasteboard:[inInfo draggingPasteboard]];
			if (draggedWords)
				ok = YES;
			else {
				NSData *data = [[inInfo draggingPasteboard] dataForType:NSFilenamesPboardType];
				if (data) {
					NSString *fileName = [[[inInfo draggingPasteboard] propertyListForType:NSFilenamesPboardType] objectAtIndex:0];
					NSString *fileType = [fileName pathExtension];
					if ([NSApp hasQTKit] && [[QTMovie movieUnfilteredFileTypes] containsObject:fileType]) {
						[self setMovieFile:fileName ofWord:[mVisibleWords objectAtIndex:inRow]];
						return YES;
					} else if ([[NSImage imageUnfilteredFileTypes] containsObject:fileType]) {
						[self setImageFile:fileName ofWord:[mVisibleWords objectAtIndex:inRow]];
						return YES;
					} else if ([[NSSound soundUnfilteredFileTypes] containsObject:fileType]) {
						int column = [mWordTableView columnAtPoint:[mWordTableView convertPoint:[inInfo draggingLocation] fromView:nil]];
						if (column >= 0) {
							NSString *columnIdentifier = [[[mWordTableView tableColumns] objectAtIndex:column] identifier];
							if ([columnIdentifier isEqual:@"Source"] || [columnIdentifier isEqual:@"Target"]) {
								[self setAudioFile:fileName forKey:columnIdentifier ofWord:[mVisibleWords objectAtIndex:inRow]];
								return YES;
							}
						}
					}
				}
			}
		}

		if (ok) {
			[self willChangeData];
			if (removeFromParents)
				[draggedWords makeObjectsPerformSelector:@selector(removeFromParent)];
			[self insertWords:draggedWords row:inRow];
			[self didChangeData];
		}
		return ok;
	} else
		return NO;
}

-(void)tableView:(NSTableView *)inTableView pasteFromPasteboard:(NSPasteboard *)inPasteboard
{
	unsigned row = [[inTableView selectedRowIndexes] lastIndex];
	if (row == NSNotFound)
		row = [mVisibleWords count];
	else
		row++;
	row = MIN(row, [mVisibleWords count]);

	NSArray *words = [self wordsFromPasteboard:inPasteboard];
	if (!words) {
		NSString *string = [inPasteboard stringForType:NSStringPboardType];
		words = [self wordsFromString:string];
	}
	
	if (words)
		[self insertWords:words row:row];
}

-(void)tableView:(NSTableView *)inTableView willDisplayCell:(id)inCell forTableColumn:(NSTableColumn *)inTableColumn row:(int)inRowIndex
{
	ProVocWord *word;
	int label;
	if ([inTableColumn isKindOfClass:[ProVocFlaggedTableColumn class]] && inRowIndex < [mVisibleWords count] && (label = [(word = [mVisibleWords objectAtIndex:inRowIndex]) label])) {
		[inCell setImage:[self imageForLabel:label flagged:[word mark] != 0]];
	}
	if ([inTableColumn isKindOfClass:[ProVocWordTableColumn class]]) {
		word = inRowIndex < [mVisibleWords count] ? [mVisibleWords objectAtIndex:inRowIndex] : nil;
		if ([[inTableColumn identifier] isEqual:@"Number"]) {
			BOOL hasImage = [word imageMedia] != nil;
			BOOL hasMovie = [word movieMedia] != nil;
			[inCell setImage:hasMovie ? [NSImage imageNamed:@"SmallMovie"] : hasImage ? [NSImage imageNamed:@"SmallImage"] : mHasVisibleMedia ? [NSImage imageNamed:@"SmallBlank"] : nil];
		} else {
			BOOL canPlayAudio = [word canPlayAudio:[inTableColumn identifier]];
			BOOL displayIcon = [[inTableColumn identifier] isEqualToString:@"Source"] ? mHasVisibleSourceAudio : mHasVisibleTargetAudio;
			[inCell setImage:canPlayAudio ? [NSImage imageNamed:@"SmallSpeaker"] : displayIcon ? [NSImage imageNamed:@"SmallBlank"] : nil];
/*			if (mCheckingSpelling && inRowIndex == mLastSpellCheckedRow && mMisspelledRange.location != NSNotFound && mLastSpellCheckedColumn == ([[inTableColumn identifier] isEqual:@"Source"] ? 0 : 1)) {
				NSString *string = [self tableView:inTableView objectValueForTableColumn:inTableColumn row:inRowIndex];
				NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
				[attributedString addAttribute:NSUnderlineColorAttributeName value:[NSColor redColor] range:mMisspelledRange];
				[attributedString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleThick | NSUnderlineStyleDouble | NSUnderlinePatternDot] range:mMisspelledRange];
				[inCell setAttributedStringValue:attributedString];
				[attributedString release];
			} */
		}
	}
}

-(NSImage *)tableView:(NSTableView *)inTableView dragImageBadgeForRowIndexes:(NSIndexSet *)inIndexSet
{
	int n = [inIndexSet count];
	if ([self displayExtraRowInTableView:inTableView] && [inIndexSet containsIndex:[self numberOfRowsInTableView:inTableView] - 1])
		n--;
	return n > 1 ? [NSImage badgeImageWithNumber:n] : nil;
}

-(NSMenu *)tableView:(NSTableView *)inTableView menuForEvent:(NSEvent *)inEvent
{
	int row = [inTableView rowAtPoint:[inTableView convertPoint:[inEvent locationInWindow] fromView:nil]];
	if (row >= 0 && row < [mVisibleWords count] && ![[inTableView selectedRowIndexes] containsIndex:row])
		[inTableView selectRow:row byExtendingSelection:([inEvent modifierFlags] & NSShiftKeyMask) != 0];
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	[menu addItemWithTitle:NSLocalizedString(@"Start Speaking", @"") action:@selector(startSpeaking:) keyEquivalent:@""];
	[menu addItemWithTitle:NSLocalizedString(@"Stop Speaking", @"") action:@selector(stopSpeaking:) keyEquivalent:@""];
	[menu addItem:[NSMenuItem separatorItem]];
	[menu addItemWithTitle:NSLocalizedString(@"Reveal Words in Pages Menu Item Title", @"") action:@selector(revealSelectedWordsInPages:) keyEquivalent:@""];
	return menu;
}

-(void)tableView:(NSTableView *)inTableView deleteContentsOfTableColumn:(NSTableColumn *)inTableColumn
{
	if (inTableView == mWordTableView) {
		NSArray *words = mVisibleWords;
		[self willChangeData];
		[words makeObjectsPerformSelector:@selector(clearValueForIdentifier:) withObject:[inTableColumn identifier]];
		[self visibleWordsDidChange];
		[self didChangeData];
	}
}

@end

@implementation ProVocDocument (Words)

static NSArray *sSelectedWords = nil;

-(void)reselectWords:(id)inSender
{
	if (!sSelectedWords)
		return;
		
	unsigned firstRow = NSNotFound, lastRow = NSNotFound;
	BOOL extend = NO;
	NSEnumerator *enumerator = [sSelectedWords objectEnumerator];
	id word;
	while (word = [enumerator nextObject]) {
		unsigned row = [mVisibleWords indexOfObjectIdenticalTo:word];
		if (row != NSNotFound) {
			[mWordTableView selectRow:row byExtendingSelection:extend];
			lastRow = row;
			if (!extend) {
				firstRow = row;
				extend = YES;
			}
		}
	}
	if (firstRow == NSNotFound)
		[mWordTableView deselectAll:nil];
	else {
		[mWordTableView scrollRowToVisible:lastRow];
		[mWordTableView scrollRowToVisible:firstRow];
	}
	
	[sSelectedWords release];
	sSelectedWords = nil;
}

-(void)keepSelectedWords
{
	[self keepWordsSelected:[self selectedWords]];
}

-(void)keepWordsSelected:(NSArray *)inWords
{
	if (!sSelectedWords) {
		sSelectedWords = [inWords copy];
		[self performSelector:@selector(reselectWords:) withObject:nil afterDelay:0.0];
	}
}

-(BOOL)canAddWord
{
	return [[self selectedPages] count] > 0;
}

-(void)updateDifficultyLimits
{
    mMaxDifficulty = 3;
    mMinDifficulty = -mMaxDifficulty;
    NSEnumerator *enumerator = [mWords objectEnumerator];
    ProVocWord *word;
    while (word = [enumerator nextObject]) {
        float difficulty = [word difficulty];
        mMinDifficulty = MIN(mMinDifficulty, difficulty);
        mMaxDifficulty = MAX(mMaxDifficulty, difficulty);
    }
}

-(NSArray *)wordsInPages:(NSArray *)inPages
{
	static NSMutableArray *words = nil;
	if (!words)
		words = [[NSMutableArray alloc] initWithCapacity:0];
	else
		[words removeAllObjects];
	
	NSEnumerator *enumerator = [inPages objectEnumerator];
	ProVocPage *page;
	while (page = [enumerator nextObject])
		[words addObjectsFromArray:[page words]];
		
	return [[words copy] autorelease];
}

-(NSArray *)allWords
{
	return [self wordsInPages:[self allPages]];
}

-(NSArray *)selectedWords
{
	static NSMutableArray *words = nil;
	if (!words)
		words = [[NSMutableArray alloc] initWithCapacity:0];
	else
		[words removeAllObjects];
		
	NSEnumerator *enumerator = [mWordTableView selectedRowEnumerator];
	id row;
	while (row = [enumerator nextObject]) {
		int index = [row intValue];
		if (index < [mVisibleWords count])
			[words addObject:[mVisibleWords objectAtIndex:index]];
	}
	return [[words copy] autorelease];
}

-(void)wordsDidChange
{
	mShowDoubles = NO;
	[mWords setArray:[self wordsInPages:[self selectedPages]]];
	
	NSEnumerator *enumerator = [mWords objectEnumerator];
	ProVocWord *word;
	int index = 1;
	while (word = [enumerator nextObject])
		[word setNumber:index++];
		
	[self updateDifficultyLimits];
	[self sortedWordsDidChange];
	[self willChangeValueForKey:@"pageSelectionTitle"];
	[self didChangeValueForKey:@"pageSelectionTitle"];
}

-(void)sortedWordsDidChange
{
	[mSortedWords setArray:mWords];
	[self sortWords:mSortedWords];
	[self visibleWordsDidChange];
}

-(void)visibleWordsDidChange
{
	if (![self showingAllWords]) {
		NSString *searchString = [mSearchString stringByRemovingAccents];
		[mVisibleWords removeAllObjects];
		NSEnumerator *enumerator = [mSortedWords objectEnumerator];
		ProVocWord *word;
		while (word = [enumerator nextObject])
			if ((!mShowDoubles || [word isDouble]) && ([searchString length] == 0 || [self doesWord:word containString:searchString]))
				[mVisibleWords addObject:word];
	} else
		[mVisibleWords setArray:mSortedWords];
	
	mHasVisibleMedia = mHasVisibleSourceAudio = mHasVisibleTargetAudio = NO;
	NSEnumerator *enumerator = [mVisibleWords objectEnumerator];
	ProVocWord *word;
	while (word = [enumerator nextObject]) {
		if ([word imageMedia] || [word movieMedia])
			mHasVisibleMedia = YES;
		if ([word canPlayAudio:@"Source"])
			mHasVisibleSourceAudio = YES;
		if ([word canPlayAudio:@"Target"])
			mHasVisibleTargetAudio = YES;
		if (mHasVisibleMedia && mHasVisibleSourceAudio && mHasVisibleTargetAudio)
			break;
	}
	
    [mWordTableView reloadData];
	[self reselectWords:nil];
	
	[self willChangeValueForKey:@"wordSelectionTitle"];
	[self didChangeValueForKey:@"wordSelectionTitle"];
}

-(NSString *)wordSelectionTitle
{
	NSString *title;
	int total = [mWords count];
	if (total == 0)
		title = NSLocalizedString(@"No word", @"");
	else if (total == 1)
		title = [NSString stringWithFormat:NSLocalizedString(@"%i word", @""), total];
	else
		title = [NSString stringWithFormat:NSLocalizedString(@"%i words", @""), total];
	int visible = [mVisibleWords count];
	if (visible != total)
		title = [NSString stringWithFormat:NSLocalizedString(@"%i of %@", @""), visible, title];
	return title;
}

-(void)deleteWords:(NSArray *)inWords
{
	[self willChangeData];
	[[self allPages] makeObjectsPerformSelector:@selector(removeWords:) withObject:inWords];
	[self wordsDidChange];
	if ([mWordTableView selectedRow] >= [mVisibleWords count])
		[mWordTableView selectRow:[mVisibleWords count] - 1 byExtendingSelection:NO];
	[self selectedWordsDidChange:nil];
	[self didChangeData];
}

static BOOL sKeepOnDoubleWordSearch = YES;

-(void)cancelDoubleWordSearch
{
	sKeepOnDoubleWordSearch = NO;
}

-(id)doubleWordsIn:(NSArray *)inWords progressDelegate:(id)inDelegate
{
	sKeepOnDoubleWordSearch = YES;
	NSMutableSet *doubles = [NSMutableSet set];
	ProVocSilentTester *tester = [[[ProVocSilentTester alloc] initWithDocument:self] autorelease];
	
	int pass, i, j, n = [inWords count];
	int count = 0, total = n * (n - 1);
	for (pass = 0; pass < 2 && sKeepOnDoubleWordSearch; pass++) {
		[tester setLanguage:pass == 0 ? [self sourceLanguage] : [self targetLanguage]];
		for (i = 0; i < n && sKeepOnDoubleWordSearch; i++) {
			ProVocWord *word = [inWords objectAtIndex:i];
			NSString *s1 = pass == 0 ? [word sourceWord] : [word targetWord];
			s1 = [tester fullGenericAnswerString:s1];
			for (j = i + 1; j < n && sKeepOnDoubleWordSearch; j++) {
				ProVocWord *otherWord = [inWords objectAtIndex:j];
				NSString *s2 = pass == 0 ? [otherWord sourceWord] : [otherWord targetWord];
				
				if ([tester isGenericString:s1 equalToString:s2]) {
					[doubles addObject:word];
					[doubles addObject:otherWord];
				}
				
				if (count++ % 20 == 0)
					[inDelegate performSelector:@selector(doubleWordSearchProgress:) withObject:[NSNumber numberWithFloat:(float)(count) / total]];
			}
		}
	}

	return sKeepOnDoubleWordSearch ? doubles : nil;
}

@end

@implementation ProVocDocument (Search)

-(BOOL)doesWord:(ProVocWord *)inWord containString:(NSString *)inSearchString
{
	unsigned options = NSLiteralSearch | NSCaseInsensitiveSearch;
	NSString *string;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults boolForKey:PVSearchSources] && (string = [[inWord sourceWord] stringByRemovingAccents]) && [string rangeOfString:inSearchString options:options].location != NSNotFound)
		return YES;
	if ([defaults boolForKey:PVSearchTargets] && (string = [[inWord targetWord] stringByRemovingAccents]) && [string rangeOfString:inSearchString options:options].location != NSNotFound)
		return YES;
	if ([defaults boolForKey:PVSearchComments] && (string = [[inWord comment] stringByRemovingAccents]) && [string rangeOfString:inSearchString options:options].location != NSNotFound)
		return YES;
	return NO;
}

-(void)showAllWords
{
	if ([mSearchString length] > 0) {
		[mSearchField setStringValue:@""];
		[mSearchString release];
		mSearchString = nil;
		mShowDoubles = NO;
		[self visibleWordsDidChange];
	}
}

-(BOOL)showingAllWords
{
	return !mShowDoubles && [mSearchString length] == 0;
}

-(void)revealSelectedWordsInPages:(id)inSender
{
	[self revealWordsInPages:[self selectedWords]];
}

-(void)revealWordsInPages:(NSArray *)inWords
{
	[self setMainTab:1];
	if ([inWords count] == 0)
		return;
	[self showAllWords];
	[self keepWordsSelected:inWords];
	NSEnumerator *enumerator = [inWords objectEnumerator];
	ProVocWord *word;
	while (word = [enumerator nextObject]) {
		NSMutableArray *itemsToExpand = [NSMutableArray array];
		id item = [word page];
		int index;
		for (;;) {
			index = [mPageOutlineView rowForItem:item];
			if (index >= 0)
				break;
			item = [item parent];
			[itemsToExpand addObject:item];
		}
		NSEnumerator *enumerator = [itemsToExpand reverseObjectEnumerator];
		while (item = [enumerator nextObject])
			[mPageOutlineView expandItem:item];
	}

	NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
	enumerator = [inWords objectEnumerator];
	while (word = [enumerator nextObject]) {
		[indexes addIndex:[mPageOutlineView rowForItem:[word page]]];
	}
	[mPageOutlineView selectRowIndexes:indexes byExtendingSelection:NO];
}

@end

@implementation ProVocDocument (Sort)

typedef struct { id identifier; BOOL descending; id determinents; BOOL ignoreCase; BOOL ignoreAccents; } SortContext;

int ORDER_BY_CONTEXT (id left, id right, void *ctxt)
{
	SortContext *context = (SortContext *)ctxt;
	int order = 0;
	id identifier = context->identifier;
	if (identifier) {
		id first, second;
		
		if (context->descending) {
			first  = [right valueForIdentifier:identifier];
			second = [left  valueForIdentifier:identifier];
		} else {
			first  = [left  valueForIdentifier:identifier];
			second = [right valueForIdentifier:identifier];
		}

		if (context->ignoreCase && [first respondsToSelector:@selector(lowercaseString)]) {
			first = [first lowercaseString];
			second = [second lowercaseString];
		}
		if (context->ignoreAccents && [first respondsToSelector:@selector(stringByRemovingAccents)]) {
			first = [first stringByRemovingAccents];
			second = [second stringByRemovingAccents];
		}
		if (context->determinents) {
			first = [first stringByDeletingWords:context->determinents];
			second = [second stringByDeletingWords:context->determinents];
		}
		
		order = [(NSString *)first compare:second];
	}
	return order;
}

-(void)sortWords:(NSMutableArray *)inWords
{
	[self sortWords:inWords sortIdentifier:[mSortingColumn identifier]];
}

-(NSArray *)determinentsOfLanguageWithIdentifier:(id)inIdentifier ignoreCase:(BOOL *)outIgnoreCase ignoreAccents:(BOOL *)outIgnoreAccents
{
	NSMutableArray *determinents = nil;
	NSString *language = nil;
	if ([inIdentifier isEqual:@"Source"])
		language = [mProVocData sourceLanguage];
	else if ([inIdentifier isEqual:@"Target"])
		language = [mProVocData targetLanguage];
	NSDictionary *languages = [[NSUserDefaults standardUserDefaults] objectForKey:PVPrefsLanguages];
    NSEnumerator *enumerator = [[languages objectForKey:@"Languages"] objectEnumerator];
    NSDictionary *description;
    while (description = [enumerator nextObject])
		if ([language isEqual:[description objectForKey:@"Name"]]) {
			if (outIgnoreCase)
				*outIgnoreCase = ![[description objectForKey:PVCaseSensitive] boolValue];
			if (outIgnoreAccents)
				*outIgnoreAccents = ![[description objectForKey:PVAccentSensitive] boolValue];
		
			NSEnumerator *enumerator = [[[description objectForKey:@"FacultativeDeterminents"] componentsSeparatedByString:@","] objectEnumerator];
			NSString *determinent;
			while (determinent = [enumerator nextObject]) {
				if (!determinents)
					determinents = [NSMutableArray array];
				[determinents addObject:[determinent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
			}
			break;
        }
	return determinents;
}

-(void)sortWords:(NSMutableArray *)inWords sortIdentifier:(id)inSortIdentifier
{
	BOOL ignoreCase = YES;
	BOOL ignoreAccents = YES;
	NSArray *determinents = [self determinentsOfLanguageWithIdentifier:inSortIdentifier ignoreCase:nil ignoreAccents:nil];
		
    SortContext context = {inSortIdentifier, mSortDescending, determinents, ignoreCase, ignoreAccents};
	if ([context.identifier isEqualToString:@"Mark"])
		context.identifier = @"MarkAndLabel";
    [inWords sortUsingFunction:ORDER_BY_CONTEXT context:&context];
}

-(void)sortWordsByColumn:(NSTableColumn *)inTableColumn
{
    if (mSortingColumn == inTableColumn)
        mSortDescending = !mSortDescending;
    else {
        mSortDescending = NO;
        if (mSortingColumn)
            [mWordTableView setIndicatorImage:nil inTableColumn:mSortingColumn];

        mSortingColumn = inTableColumn;
        [mWordTableView setHighlightedTableColumn:mSortingColumn];
    }
    [mWordTableView setIndicatorImage:mSortDescending ? [NSTableView descendingSortIndicator] : [NSTableView ascendingSortIndicator] inTableColumn:mSortingColumn];

	[self keepSelectedWords];
    [self sortedWordsDidChange];
}

-(BOOL)isSortingByNumber
{
    return [[mSortingColumn identifier] isEqualTo:@"Number"];
}

static BOOL lastColumnClick = NO;
static NSTimeInterval waitTime = 0;

-(void)tableView:(NSTableView*)inTableView didClickTableColumn:(NSTableColumn *)inTableColumn
{
	if (inTableView == mWordTableView)
		if ([NSDate timeIntervalSinceReferenceDate] > waitTime) {
			[[inTableView window] makeFirstResponder:inTableView];
			[self sortWordsByColumn:inTableColumn];
			lastColumnClick = NO;
		}
}

-(void)tableView:(NSTableView *)inTableView mouseDownInHeaderOfTableColumn:(NSTableColumn *)inTableColumn
{
	if (inTableView == mWordTableView)
		if (lastColumnClick && [[NSApp currentEvent] clickCount] > 1) {
			NSPoint point = [inTableView convertPoint:[[NSApp currentEvent] locationInWindow] fromView:nil];
			point.x -= 10;
			point.y = 0;
			int columnIndex = [inTableView columnAtPoint:point];
			NSTableColumn *column = columnIndex >= 0 ? [[inTableView tableColumns] objectAtIndex:columnIndex] : inTableColumn;
			[self tableView:inTableView autoSizeTableColumn:column];
			waitTime = [NSDate timeIntervalSinceReferenceDate] + 0.1;
		} else
			lastColumnClick = YES;
}

@end

@implementation ProVocDocument (AutoSizeColumns)

-(void)tableView:(NSTableView *)inTableView autoSizeTableColumn:(NSTableColumn *)inTableColumn
{
	id dataSource = [inTableView dataSource];
	float maxWidth = 0;
	int row;
	for (row = 0; row < [inTableView numberOfRows]; row++) {
		id cell = [inTableColumn dataCellForRow:row];
		NSString *string = [dataSource tableView:inTableView objectValueForTableColumn:inTableColumn row:row];
		if (string) {
			[cell setStringValue:string];
			maxWidth = MAX(maxWidth, [cell cellSize].width);
		}
	}
	[inTableColumn setWidth:maxWidth];
}

@end

@implementation ProVocDocument (Pages)

-(void)pagesDidChange
{
	[mPageOutlineView reloadData];
	[self selectedPagesDidChange];
}

-(void)selectedPagesDidChange
{
	[mSelectedPages removeAllObjects];
	NSEnumerator *enumerator = [mPageOutlineView selectedRowEnumerator];
	id row;
	while (row = [enumerator nextObject]) {
		id page = [mPageOutlineView itemAtRow:[row intValue]];
		if ([page isKindOfClass:[ProVocChapter class]]) {
			NSEnumerator *enumerator = [[page allPages] objectEnumerator];
			ProVocPage *subpage;
			while (subpage = [enumerator nextObject])
				if (![mSelectedPages containsObject:subpage])
					[mSelectedPages addObject:subpage];
		} else if ([page isKindOfClass:[ProVocPage class]])
			if (![mSelectedPages containsObject:page])
				[mSelectedPages addObject:page];
	}

	[self wordsDidChange];
	[self willChangeValueForKey:@"canAddWord"];
	[self didChangeValueForKey:@"canAddWord"];
}

-(NSArray *)selectedSourceAncestors
{
	NSMutableArray *ancestors = [NSMutableArray array];
	NSEnumerator *enumerator = [mPageOutlineView selectedRowEnumerator];
	id row;
	while (row = [enumerator nextObject]) {
		id source = [mPageOutlineView itemAtRow:[row intValue]];
		[ancestors addObject:source];
	}
	return [ancestors commonAncestors];
}

-(NSArray *)selectedPages
{
	return mSelectedPages;
}

-(ProVocPage *)currentPage
{
	return [[self selectedPages] lastObject];
}

-(NSArray *)allPages
{
	return [[mProVocData rootChapter] allPages];
}

-(void)rightRatioDidChange:(NSNotification *)inNotification
{
	[self updateDifficultyLimits];
	[mWordTableView reloadData];
}

-(void)reviewFactorDidChange:(NSNotification *)inNotification
{
	[mWordTableView reloadData];
	[self currentPresetDidChange:nil];
}

-(NSString *)pageSelectionTitle
{
	NSString *pages;
	int n = [mSelectedPages count];
    if (n <= 1)
        pages = [NSString stringWithFormat:NSLocalizedString(@"%i page selected", @""), n];
    else
        pages = [NSString stringWithFormat:NSLocalizedString(@"%i pages selected", @""), n];
	
	int words = [mWords count];
	int wordsToTest = [[self wordsToBeTested] count];
	NSString *wordsCaption;
	if (words <= 1) {
		if (wordsToTest == words)
	        wordsCaption = [NSString stringWithFormat:NSLocalizedString(@"%i word to test", @""), words];
		else
	        wordsCaption = [NSString stringWithFormat:NSLocalizedString(@"%i of %i word to test", @""), wordsToTest, words];
	} else {
		if (wordsToTest == words)
	        wordsCaption = [NSString stringWithFormat:NSLocalizedString(@"%i words to test", @""), words];
		else
	        wordsCaption = [NSString stringWithFormat:NSLocalizedString(@"%i of %i words to test", @""), wordsToTest, words];
	}
		
	return [NSString stringWithFormat:NSLocalizedString(@"pages: %@ and words: %@", @""), pages, wordsCaption];
}

-(void)outlineView:(NSOutlineView *)inOutlineView willDisplayCell:(NSCell *)inCell forTableColumn:(NSTableColumn *)inTableColumn item:(id)inItem
{
	if ([inCell isKindOfClass:[ImageAndTextCell class]]) {
		NSString *iconName = [self outlineView:inOutlineView isItemExpandable:inItem] ? @"album" : @"page";
		[(ImageAndTextCell *)inCell setImage:[NSImage imageNamed:iconName]];
	}
}

@end

@implementation ProVocDocument (Languages)

+(NSMutableArray *)languageNames
{
    NSMutableArray *names = [NSMutableArray array];
    NSDictionary *languages = [[NSUserDefaults standardUserDefaults] objectForKey:PVPrefsLanguages];
    NSEnumerator *enumerator = [[languages objectForKey:@"Languages"] objectEnumerator];
    NSDictionary *description;
    while (description = [enumerator nextObject])
        [names addObject:[description objectForKey:@"Name"]];
    return names;
}

+(NSMutableArray *)languageNamesIncluding:(NSString *)inLanguage
{
    NSMutableArray *languages = [self languageNames];
    if (inLanguage && ![languages containsObject:inLanguage])
        [languages addObject:inLanguage];
    return languages;
}

-(void)updateSourceLanguagePopUp
{
    NSString *sourceLanguage = [mProVocData sourceLanguage];
    NSArray *languages = [[self class] languageNamesIncluding:sourceLanguage];
    NSEnumerator *enumerator = [languages objectEnumerator];
    NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"Source"] autorelease];
    NSString *language;
    while (language = [enumerator nextObject])
        [menu addItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Language PopUp Item Format (%@)", @""), language]
								action:@selector(sourcePopUpAction:) keyEquivalent:@""];
	[menu addItem:[NSMenuItem separatorItem]];
	[menu addItemWithTitle:NSLocalizedString(@"More Language Item", @"") action:@selector(sourcePopUpAction:) keyEquivalent:@""];
    [mSourceLanguagePopUp setMenu:menu];
    [mSourceLanguagePopUp selectItemAtIndex:[languages indexOfObject:sourceLanguage]];
}

-(void)updateTargetLanguagePopUp
{
    NSString *targetLanguage = [mProVocData targetLanguage];
    NSArray *languages = [[self class] languageNamesIncluding:targetLanguage];
    NSEnumerator *enumerator = [languages objectEnumerator];
    NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"Target"] autorelease];
    NSString *language;
    while (language = [enumerator nextObject])
        [menu addItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Language PopUp Item Format (%@)", @""), language]
                                action:@selector(targetPopUpAction:) keyEquivalent:@""];
	[menu addItem:[NSMenuItem separatorItem]];
	[menu addItemWithTitle:NSLocalizedString(@"More Language Item", @"") action:@selector(targetPopUpAction:) keyEquivalent:@""];
    [mTargetLanguagePopUp setMenu:menu];
    [mTargetLanguagePopUp selectItemAtIndex:[languages indexOfObject:targetLanguage]];
}

-(void)updateLanguagePopUps
{    
    [self updateSourceLanguagePopUp];
    [self updateTargetLanguagePopUp];
}

-(void)languageNamesDidChange:(NSNotification *)inNotification
{
    [self updateLanguagePopUps];
}

-(void)languagesDidChange
{
	[self willChangeValueForKey:@"sourceLanguage"];
	[self willChangeValueForKey:@"targetLanguage"];
    [self updateLanguagePopUps];
	[self didChangeValueForKey:@"sourceLanguage"];
	[self didChangeValueForKey:@"targetLanguage"];
}

-(IBAction)sourcePopUpAction:(id)inSender
{
    NSString *language = [mProVocData sourceLanguage];
    NSArray *languages = [[self class] languageNamesIncluding:language];
    int index = [mSourceLanguagePopUp indexOfItem:inSender];
	if (index >= [languages count]) {
	    [mSourceLanguagePopUp selectItemAtIndex:[languages indexOfObject:[mProVocData sourceLanguage]]];
		[[ProVocPreferences sharedPreferences] openLanguageView:nil];
	} else {
		[self willChangeLanguages];
	    [mProVocData setSourceLanguage:[languages objectAtIndex:index]];
		[self didChangeLanguages];
		[self languagesDidChange];
	}
	[self documentParameterDidChange:nil];
}

-(IBAction)targetPopUpAction:(id)inSender
{
    NSString *language = [mProVocData targetLanguage];
    NSArray *languages = [[self class] languageNamesIncluding:language];
    int index = [mTargetLanguagePopUp indexOfItem:inSender];
	if (index >= [languages count]) {
	    [mTargetLanguagePopUp selectItemAtIndex:[languages indexOfObject:[mProVocData targetLanguage]]];
		[[ProVocPreferences sharedPreferences] openLanguageView:nil];
	} else {
		[self willChangeLanguages];
		[mProVocData setTargetLanguage:[languages objectAtIndex:index]];
		[self languagesDidChange];
		[self didChangeLanguages];
	}
	[self documentParameterDidChange:nil];
}

@end

@implementation ProVocDocument (Encoding)

-(BOOL)useCustomEncoding
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"CustomStringEncoding"];
}

-(NSStringEncoding)stringEncoding
{
	id value = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExportStringEncoding"];
	NSStringEncoding encoding = value ? [value unsignedIntValue] : [NSString defaultCStringEncoding];
	return encoding;
}

-(const NSStringEncoding *)availableStringEncodings
{
	static NSStringEncoding *encodings = nil;
	if (!encodings) {
		encodings = (NSStringEncoding *)calloc(50, sizeof(NSStringEncoding));
		NSStringEncoding *myEncodings = encodings;
		const NSStringEncoding *encodings = [NSString availableStringEncodings];
		NSStringEncoding encoding;
		while (encoding = *encodings++)
			if (encoding <= 30)
				*myEncodings++ = encoding;
		*myEncodings = nil;
	}
	return encodings;
}

-(NSArray *)localizedNamesOfStringEncodings
{
	NSMutableArray *names = [NSMutableArray array];
	[names addObject:NSLocalizedString(@"Default String Encoding Menu Title", @"")];
	const NSStringEncoding *encodings = [self availableStringEncodings];
	NSStringEncoding encoding;
	while (encoding = *encodings++)
		[names addObject:[NSString localizedNameOfStringEncoding:encoding]];
	return names;
}

-(int)stringEncodingIndex
{
	if (![self useCustomEncoding])
		return 0;
	NSStringEncoding encoding = [self stringEncoding];
	int index = 1;
	const NSStringEncoding *encodings = [self availableStringEncodings];
	while (*encodings) {
		if (encoding == *encodings)
			break;
		index++;
		encodings++;
	}
	return index;
}

-(void)setStringEncodingIndex:(int)inIndex
{
	BOOL custom = inIndex > 0;
	[[NSUserDefaults standardUserDefaults] setBool:custom forKey:@"CustomStringEncoding"];
	if (custom) {
		NSStringEncoding encoding = [self availableStringEncodings][inIndex - 1];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithUnsignedInt:encoding] forKey:@"ExportStringEncoding"];
	}
}

@end

@implementation ProVocDocument (Labels)

+(NSColor *)colorForLabel:(int)inLabel
{
	if (inLabel == 0)
		return [NSColor colorWithCalibratedWhite:1.0 alpha:0.0];
	else {
		NSArray *labels = [[NSUserDefaults standardUserDefaults] objectForKey:PVLabels];
		int index = MIN([labels count] - 1, inLabel - 1);
		return [NSUnarchiver unarchiveObjectWithData:[[labels objectAtIndex:index] objectForKey:PVLabelColorData]];
	}
}

-(NSColor *)colorForLabel:(int)inLabel
{
	return [[self class] colorForLabel:inLabel];
}

static NSMutableDictionary *sCachedImages = nil;

+(NSImage *)imageForLabel:(int)inLabel
{
	NSColor *color = [self colorForLabel:inLabel];
	NSImage *image = [sCachedImages objectForKey:color];
	if (image)
		return image;
		
	if (!sCachedImages)
		sCachedImages = [[NSMutableDictionary alloc] initWithCapacity:0];
	NSSize size = NSMakeSize(16, 12);
	image = [[[NSImage alloc] initWithSize:size] autorelease];
	[sCachedImages setObject:image forKey:color];

	static NSShadow *shadow = nil;
	if (!shadow) {
		shadow = [[NSShadow alloc] init];
		[shadow setShadowOffset:NSMakeSize(0, -1)];
		[shadow setShadowColor:[NSColor grayColor]];
		[shadow setShadowBlurRadius:2];
	}
	
	NSRect rect = NSInsetRect(NSMakeRect(0, 0, size.width, size.height), 4, 2);
//	NSBezierPath *bezierPath = [NSBezierPath bezierPathWithOvalInRect:rect];
	NSBezierPath *bezierPath = [NSBezierPath bezierPathWithRoundRectInRect:rect radius:2];
	NSArray *colors = [NSArray arrayWithObjects:color, [color blendedColorWithFraction:0.5 ofColor:[NSColor whiteColor]], nil];
	
	[image lockFocus];
	[NSGraphicsContext saveGraphicsState];
	[shadow set];
	[[NSColor whiteColor] set];
	[bezierPath fill];
	[bezierPath fillWithColors:colors angleInDegrees:90];
	[NSGraphicsContext restoreGraphicsState];
	[[[color blendedColorWithFraction:0.5 ofColor:[NSColor blackColor]] colorWithAlphaComponent:0.5] set];
//	bezierPath = [NSBezierPath bezierPathWithOvalInRect:NSInsetRect(rect, -0.5, -0.5)];
	bezierPath = [NSBezierPath bezierPathWithRoundRectInRect:NSInsetRect(rect, -0.5, -0.5) radius:2];
	[bezierPath setLineWidth:1.0];
	[bezierPath stroke];
	[image unlockFocus];

	return image;
}

-(NSImage *)imageForLabel:(int)inLabel
{
	return [[self class] imageForLabel:inLabel];
}

static NSMutableDictionary *sCachedFlaggedImages[2] = {nil, nil};

-(NSImage *)imageForLabel:(int)inLabel flagged:(BOOL)inFlagged
{
	NSColor *color = [self colorForLabel:inLabel];
	NSImage *image = [sCachedFlaggedImages[inFlagged] objectForKey:color];
	if (image)
		return image;
		
	if (!sCachedFlaggedImages[inFlagged])
		sCachedFlaggedImages[inFlagged] = [[NSMutableDictionary alloc] initWithCapacity:0];
	NSSize size = NSMakeSize(16, 16);
	image = [[[NSImage alloc] initWithSize:size] autorelease];
	[sCachedFlaggedImages[inFlagged] setObject:image forKey:color];

	static NSShadow *shadow = nil;
	if (!shadow) {
		shadow = [[NSShadow alloc] init];
		[shadow setShadowOffset:NSMakeSize(0, -1)];
		[shadow setShadowColor:[NSColor grayColor]];
		[shadow setShadowBlurRadius:2];
	}

	NSRect rect = NSInsetRect(NSMakeRect(0, 0, size.width, size.height), 1, 1);
	rect.origin.y++;
//	NSBezierPath *bezierPath = [NSBezierPath bezierPathWithOvalInRect:rect];
	NSBezierPath *bezierPath = [NSBezierPath bezierPathWithRoundRectInRect:rect radius:2];
//	NSArray *colors = [NSArray arrayWithObjects:color, [color blendedColorWithFraction:0.5 ofColor:[NSColor whiteColor]], nil];
	
	[image lockFocus];
	[NSGraphicsContext saveGraphicsState];
	[shadow set];
	[color set];
//	[[NSColor whiteColor] set];
	[bezierPath fill];
//	[bezierPath fillWithColors:colors angleInDegrees:90];
	[NSGraphicsContext restoreGraphicsState];
	[[[color blendedColorWithFraction:0.5 ofColor:[NSColor blackColor]] colorWithAlphaComponent:0.5] set];
//	bezierPath = [NSBezierPath bezierPathWithOvalInRect:NSInsetRect(rect, -0.5, -0.5)];
	bezierPath = [NSBezierPath bezierPathWithRoundRectInRect:NSInsetRect(rect, -0.5, -0.5) radius:2];
	[bezierPath setLineWidth:1.0];
//	[bezierPath stroke];
	if (inFlagged)
		[[NSImage imageNamed:@"flagged"] dissolveToPoint:NSZeroPoint fraction:1.0];
	[image unlockFocus];

	return image;
}

-(NSString *)stringForLabel:(int)inLabel
{
	if (inLabel == 0)
		return NSLocalizedString(@"None Label Title", @"");
	else {
		NSArray *labels = [[NSUserDefaults standardUserDefaults] objectForKey:PVLabels];
		int index = MIN([labels count] - 1, inLabel - 1);
		return [[labels objectAtIndex:index] objectForKey:PVLabelTitle];
	}
}

+(void)labelColorsDidChange
{
	[sCachedImages release];
	sCachedImages = nil;
	int i;
	for (i = 0; i < 2; i++) {
		[sCachedFlaggedImages[i] release];
		sCachedFlaggedImages[i] = nil;
	}
	
	[[[NSDocumentController sharedDocumentController] documents] makeObjectsPerformSelector:@selector(updateTestOnlyPopUpMenu)];
}

+(void)labelTitlesDidChange
{
	[[[NSDocumentController sharedDocumentController] documents] makeObjectsPerformSelector:@selector(updateTestOnlyPopUpMenu)];
}

-(void)updateTestOnlyPopUpMenu
{
	[self willChangeValueForKey:@"labels"];
	[self didChangeValueForKey:@"labels"];
}

-(NSArray *)labels
{
	if (!mLabels) {
		NSMutableArray *array = [NSMutableArray array];
		int index;
		for (index = -1; index <= 9; index++) {
			ProVocLabel *label = [[ProVocLabel alloc] initWithDocument:self index:index];
			[array addObject:label];
			[label release];
		}
		mLabels = [array copy];
	}
	return mLabels;
}

@end

@implementation ProVocDocument (RecordSound)

-(void)recordSound:(id)inSender
{
	if (![[ProVocInspector sharedInspector] canRecordAudio]) {
		NSRunAlertPanel(NSLocalizedString(@"No Selection Record Audio Title", @""), NSLocalizedString(@"No Selection Record Audio Message", @""), nil, nil, nil);
		return;
	}
	NSString *key = [inSender tag] == 0 ? @"Source" : @"Target";
	[[ProVocInspector sharedInspector] recordAudioImmediately:key];
}

@end

@implementation ProVocLabel

-(id)initWithDocument:(ProVocDocument *)inDocument index:(int)inIndex
{
	if (self = [super init]) {
		mDocument = inDocument;
		mIndex = inIndex;
	}
	return self;
}

-(NSImage *)image
{
	return mIndex < 0 ? [NSImage imageNamed:@"flagged"] : [mDocument imageForLabel:mIndex];
}

-(NSString *)name
{
	return mIndex < 0 ? NSLocalizedString(@"Flagged Words Title", @"") : [mDocument stringForLabel:mIndex];
}

@end

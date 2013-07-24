//
//  ProVocDocument+Columns.m
//  ProVoc
//
//  Created by Simon Bovet on 26.05.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ProVocDocument+Columns.h"

#import "ProVocTableColumns.h"
#import "MenuExtensions.h"
#import "ProVocDocument+Lists.h"

@implementation ProVocDocument (Columns)

-(NSArray *)togglableColumnIdentifiers
{
	static NSArray *array = nil;
	if (!array)
		array = [[NSArray alloc] initWithObjects:@"Comment", @"Difficulty", @"Mark", @"LastAnswered", @"NextReview", nil];
	return array;
}

-(NSTableColumn *)columnWithIdentifier:(NSString *)inIdentifier
{
	NSEnumerator *enumerator = [mAllWordTableColumns objectEnumerator];
	NSTableColumn *column;
	while (column = [enumerator nextObject])
		if ([[column identifier] isEqual:inIdentifier])
			return column;
	return nil;
}

-(NSTableColumn *)columnWithName:(NSString *)inName
{
	NSEnumerator *enumerator = [mAllWordTableColumns objectEnumerator];
	NSTableColumn *column;
	while (column = [enumerator nextObject])
		if ([[[column headerCell] stringValue] isEqual:inName])
			return column;
	if ([inName isEqual:NSLocalizedString(@"Mark Column Name", @"")]) {
		NSEnumerator *enumerator = [mAllWordTableColumns objectEnumerator];
		NSTableColumn *column;
		while (column = [enumerator nextObject])
			if ([[column identifier] isEqual:@"Mark"])
				return column;
	}
	return nil;
}

-(NSString *)nameForColumnWithIdentifier:(NSString *)inIdentifier
{
	if ([inIdentifier isEqual:@"Mark"])
		return NSLocalizedString(@"Mark Column Name", @"");
	NSEnumerator *enumerator = [mAllWordTableColumns objectEnumerator];
	NSTableColumn *column;
	while (column = [enumerator nextObject])
		if ([[column identifier] isEqual:inIdentifier])
			return [[column headerCell] stringValue];
	return nil;
}

-(void)initializeColumns
{
	ProVocTableHeaderView *headerView = [[[ProVocTableHeaderView alloc] initWithFrame:[[mWordTableView headerView] frame]] autorelease];
	[mWordTableView setHeaderView:headerView];
	[headerView setDelegate:self];
	
	mAllWordTableColumns = [[mWordTableView tableColumns] copy];

	NSMenu *menu = [headerView menu];
	[menu addItem:[NSMenuItem separatorItem]];
	NSEnumerator *enumerator = [[self togglableColumnIdentifiers] objectEnumerator];
	NSString *identifier;
	while (identifier = [enumerator nextObject])
		[menu addItemWithTitle:[self nameForColumnWithIdentifier:identifier] target:self selector:@selector(toggleColumn:)];
}

-(BOOL)isColumnVisible:(NSTableColumn *)inTableColumn
{
	return [[mWordTableView tableColumns] containsObject:inTableColumn];
}

-(BOOL)validate:(BOOL *)outFlag columnMenuItem:(NSMenuItem *)inItem
{
	if ([inItem action] == @selector(toggleColumn:)) {
		NSTableColumn *column = [self columnWithName:[inItem title]];
		[inItem setState:[self isColumnVisible:column] ? NSOnState : NSOffState];
		if (outFlag)
			*outFlag = YES;
		return YES;
	}
	return NO;
}

-(void)toggleTableColumn:(NSTableColumn *)inColumn sizeToFit:(BOOL)inSizeToFit
{
	if (mSortingColumn == inColumn)
 	   [self sortWordsByColumn:[mWordTableView tableColumnWithIdentifier:@"Number"]];
	
	if ([self isColumnVisible:inColumn]) {
		[mWordTableView removeTableColumn:inColumn];
		if (inSizeToFit)
			[mWordTableView sizeToFit];
	} else {
		BOOL found = NO;
		int previousColumn = -1;
		NSEnumerator *enumerator = [[self togglableColumnIdentifiers] reverseObjectEnumerator];
		NSString *identifier;
		while (identifier = [enumerator nextObject])
			if (found) {
				previousColumn = [mWordTableView columnWithIdentifier:identifier];
				if (previousColumn >= 0)
					break;
			} else if ([identifier isEqual:[inColumn identifier]])
				found = YES;
		if (previousColumn < 0)
			previousColumn = MAX([mWordTableView columnWithIdentifier:@"Source"], [mWordTableView columnWithIdentifier:@"Target"]);
		[mWordTableView addTableColumn:inColumn];
		[mWordTableView moveColumn:[mWordTableView numberOfColumns] - 1 toColumn:previousColumn + 1];
	}
}

-(void)toggleColumn:(id)inSender
{
	NSTableColumn *column = [self columnWithName:[inSender title]];
	[self toggleTableColumn:column sizeToFit:YES];
}

-(void)makeColumnWithIdentifier:(NSString *)inIdentifier visible:(BOOL)inVisible
{
	NSTableColumn *column = [mWordTableView tableColumnWithIdentifier:inIdentifier];
	if ([self isColumnVisible:column] != inVisible)
		[self toggleTableColumn:column sizeToFit:YES];
}

-(NSMutableDictionary *)columnVisibility
{
	NSMutableDictionary *visibility = [NSMutableDictionary dictionary];
	NSEnumerator *enumerator = [[self togglableColumnIdentifiers] objectEnumerator];
	NSString *identifier;
	while (identifier = [enumerator nextObject]) {
		NSTableColumn *column = [mWordTableView tableColumnWithIdentifier:identifier];
		BOOL visible = [self isColumnVisible:column];
		[visibility setObject:[NSNumber numberWithBool:visible] forKey:identifier];
	}
	return visibility;
}

-(void)setColumnVisibility:(NSDictionary *)inVisibility
{
	BOOL changed = NO;
	NSEnumerator *enumerator = [inVisibility keyEnumerator];
	NSString *identifier;
	while (identifier = [enumerator nextObject]) {
		NSTableColumn *column = [self columnWithIdentifier:identifier];
		if ([self isColumnVisible:column] != [[inVisibility objectForKey:identifier] boolValue]) {
			[self toggleTableColumn:column sizeToFit:NO];
			changed = YES;
		}
	}
	if (changed)
		[mWordTableView sizeToFit];
}

-(IBAction)viewOptions:(id)inSender
{
	ProVocViewOptions *viewOptions = [[[ProVocViewOptions alloc] initWithDocument:self] autorelease];
	[viewOptions runModal];
}

@end

@implementation ProVocViewOptions

-(id)initWithDocument:(ProVocDocument *)inDocument
{
	if (self = [super initWithWindowNibName:@"ProVocViewOptions"]) {
		mDocument = [inDocument retain];
		mColumnVisibility = [[mDocument columnVisibility] retain];
	}
	return self;
}

-(void)dealloc
{
	[mColumnVisibility release];
	[mDocument release];
	[super dealloc];
}

-(void)runModal
{
	[self retain];
	[NSApp beginSheet:[self window] modalForWindow:[mDocument window] modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

-(void)sheetDidEnd:(NSWindow *)inSheet returnCode:(int)inReturnCode contextInfo:(void *)inContextInfo
{
	[[self window] orderOut:nil];
	if (inReturnCode == NSOKButton)
		[mDocument setColumnVisibility:mColumnVisibility];
	[self autorelease];
}

-(IBAction)close:(id)inSender
{
	[NSApp endSheet:[self window] returnCode:[inSender tag]];
}

-(id)valueForKey:(NSString *)inKey
{
	id value = [mColumnVisibility objectForKey:inKey];
	if (value)
		return value;
	else
		return [super valueForKey:inKey];
}

-(void)setValue:(id)inValue forKey:(NSString *)inKey
{
	if ([mColumnVisibility objectForKey:inKey])
		[mColumnVisibility setObject:inValue forKey:inKey];
	else
		[super setValue:inValue forKey:inKey];
}

@end

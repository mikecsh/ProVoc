//
//  ProVocTableView.h
//  ProVoc
//
//  Created by Simon Bovet on Mon Apr 28 2003.
//  Copyright (c) 2003 Arizona Software. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface ProVocDeletableTableView : NSTableView

@end

@interface ProVocTableView : ProVocDeletableTableView

@end

@interface NSObject (ProVocTableSource)

-(void)deleteSelectedRowsInTableView:(NSTableView *)inTableView;
-(BOOL)tableView:(NSTableView *)inTableView canPasteFromPasteboard:(NSPasteboard *)inPasteboard;
-(void)tableView:(NSTableView *)inTableView pasteFromPasteboard:(NSPasteboard *)inPasteboard;

@end


@interface ProVocOutlineView : NSOutlineView

@end

@interface NSObject (ProVocOutlineViewSource)

-(void)deleteSelectedRowsInOutlineView:(NSOutlineView *)inOutlineView;
-(BOOL)outlineView:(NSOutlineView *)inOutlineView canPasteFromPasteboard:(NSPasteboard *)inPasteboard;
-(void)outlineView:(NSOutlineView *)inOutlineView pasteFromPasteboard:(NSPasteboard *)inPasteboard;

@end


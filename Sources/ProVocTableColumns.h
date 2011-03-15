//
//  ProVocTableColumns.h
//  ProVoc
//
//  Created by Simon Bovet on Mon Apr 28 2003.
//  Copyright (c) 2003 Arizona Software. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface ProVocDifficultyTableColumn : NSTableColumn  {
	NSCell *mDataCell;
}

@end

@interface ProVocFlaggedTableColumn : NSTableColumn {
	NSCell *mDataCell;
}

@end

@interface ProVocPresetTableColumn : NSTableColumn {
	NSCell *mDataCell;
}

@end

@interface ProVocWordTableColumn : NSTableColumn {
	NSCell *mDataCell;
}

@end

@interface ProVocTableHeaderView : NSTableHeaderView {
	id mDelegate;
	NSMenu *mMenu;
	int mCurrentColumnIndex;
}

-(void)setDelegate:(id)inDelegate;

@end

@interface NSObject (AutoSizeColumns)

-(void)tableView:(NSTableView *)inTableView autoSizeTableColumn:(NSTableColumn *)inTableColumn;
-(void)tableView:(NSTableView *)inTableView deleteContentsOfTableColumn:(NSTableColumn *)inTableColumn;

@end
//
//  ProVocSpotlighter.m
//  ProVoc
//
//  Created by Simon Bovet on 15.05.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ProVocSpotlighter.h"


@implementation ProVocSpotlighter

-(id)init
{
	if (self = [self initWithWindowNibName:@"ProVocSpotlighter"]) {
		mQuery = [[NSMetadataQuery alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryNotification:) name:nil object:mQuery];
	}
	return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

-(NSArray *)searchFiles
{
	[self performSelector:@selector(startQuery:) withObject:nil afterDelay:0.0 inModes:@[NSModalPanelRunLoopMode]];
	int returnCode = [NSApp runModalForWindow:[self window]];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[mQuery stopQuery];
	[[self window] orderOut:nil];
	if (returnCode == NSCancelButton)
		return nil;
	else {
		int i, n = [mQuery resultCount];
		NSMutableArray *array = [NSMutableArray arrayWithCapacity:n];
		for (i = 0; i < n; i++)
			[array addObject:[[mQuery resultAtIndex:i] valueForAttribute:(id)kMDItemPath]];
		return array;
	}
}

-(NSArray *)allProVocFiles
{
	[mSearchString release];
	mSearchString = nil;
	return [self searchFiles];
}

-(NSArray *)allProVocFilesContaining:(NSString *)inSearchString
{
	if (mSearchString != inSearchString) {
		[mSearchString release];
		mSearchString = [inSearchString retain];
	}
	return [self searchFiles];
}

-(void)startQuery:(id)inSender
{
	NSPredicate *predicate;
	if ([mSearchString length] == 0)
		predicate = [NSPredicate predicateWithFormat:@"kMDItemContentType == 'ch.arizona-software.provoc.vocabulary'"];
	else {
		NSMutableString *search = [mSearchString mutableCopy];
		[search replaceOccurrencesOfString:@"'" withString:[NSString stringWithFormat:@"%C'", 0x005C] options:0 range:NSMakeRange(0, [search length])];
		predicate = [NSPredicate predicateWithFormat:@"(kMDItemContentType == 'ch.arizona-software.provoc.vocabulary') AND (kMDItemTextContent LIKE[cd] %@)", search];
		[search release];
	}
	[mQuery setPredicate:predicate];
	[mQuery setSortDescriptors:@[[[[NSSortDescriptor alloc] initWithKey:(id)kMDItemLastUsedDate ascending:NO] autorelease]]];
	[mQuery setValueListAttributes:@[(id)kMDItemPath]];
	[mQuery startQuery];
}

-(IBAction)cancel:(id)inSender
{
	[NSApp stopModalWithCode:NSCancelButton];
}

-(void)queryNotification:(NSNotification *)inNotification
{
    if ([[inNotification name] isEqualToString:NSMetadataQueryDidFinishGatheringNotification])
		[NSApp stopModalWithCode:NSOKButton];
}

-(BOOL)searching
{
	return YES;
}

@end

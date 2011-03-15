//
//  ProVocAppDelegate.m
//  ProVoc
//
//  Created by bovet on Mon Feb 10 2003.
//  Copyright (c) 2003 Arizona Software. All rights reserved.
//

#import "ProVocAppDelegate.h"
#import "ProVocPreferences.h"
#import "ProVocDocument.h"
#import "ProVocDocument+Lists.h"
#import "ProVocDocument+Export.h"
#import "ProVocDocument+Slideshow.h"
#import "ProVocTester.h"
#import "ProVocPrintView.h"
#import "ProVocCardsView.h"
#import "TransformerExtensions.h"
#import "iPodController.h"
#import "iPodManager.h"
#import "ProVocInspector.h"
#import "ProVocBackground.h"
#import "ProVocStartingPoint.h"
#import "ProVocCardController.h"
#import "ProVocServiceProvider.h"

#import "ARAboutDialog.h"
#import <ARCheckForUpdates/ARCheckForUpdates.h>

@implementation ProVocAppDelegate

+ (void)initialize
{
	unsigned seed = time(nil) % 32000;
	srand(seed);

	[NSValueTransformer setValueTransformer:[[[PercentTransformer alloc] init] autorelease] forName:@"PercentTransformer"];
	[NSValueTransformer setValueTransformer:[[[PVSizeTransformer alloc] init] autorelease] forName:@"SizeTransformer"];
	[NSValueTransformer setValueTransformer:[[[PVSearchFontSizeTransformer alloc] init] autorelease] forName:@"SearchFontSizeTransformer"];
	[NSValueTransformer setValueTransformer:[[[PVInputFontSizeTransformer alloc] init] autorelease] forName:@"InputFontSizeTransformer"];
	[NSValueTransformer setValueTransformer:[[[PVWritingDirectionToAlignmentTransformer alloc] init] autorelease] forName:@"WritingDirectionToAlignmentTransformer"];
	[NSValueTransformer setValueTransformer:[[[EnabledTextColorTransformer alloc] init] autorelease] forName:@"EnabledTextColorTransformer"];
	[NSValueTransformer setValueTransformer:[[[TimerDurationTransformer alloc] init] autorelease] forName:@"TimerDurationTransformer"];

    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
    
    [defaultValues setObject:@"" forKey:@"translationCaption"];
    [defaultValues setObject:[NSNumber numberWithFloat:150] forKey:@"Image MCQ Line Height"];
	
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:PVPrefsUseSynonymSeparator];
    [defaultValues setObject:@"/" forKey:PVPrefSynonymSeparator];
	[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:PVPrefTestSynonymsSeparately];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:PVPrefsUseCommentsSeparator];
    [defaultValues setObject:@";" forKey:PVPrefCommentsSeparator];
    [defaultValues setObject:[NSNumber numberWithFloat:2.0] forKey:PVPrefsRightRatio];

    [defaultValues setObject:[NSNumber numberWithInt:2] forKey:PVLearnedConsecutiveRepetitions];
    [defaultValues setObject:[NSNumber numberWithInt:2] forKey:PVLearnedDistractInterval];
	
    [defaultValues setObject:[NSNumber numberWithFloat:50] forKey:PVReviewLearningFactor];
    [defaultValues setObject:[NSNumber numberWithFloat:50] forKey:PVReviewTrainingFactor];
	
	id value;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:ProVocCardDisplayFrames];
	[defaultValues setObject:[NSNumber numberWithInt:2] forKey:ProVocCardPaperSides];
	[defaultValues setObject:[NSNumber numberWithFloat:1.0] forKey:ProVocCardTextSize];
	[defaultValues setObject:[NSNumber numberWithInt:0] forKey:ProVocCardDisplayComments];
	[defaultValues setObject:[NSNumber numberWithFloat:1.0] forKey:ProVocCardCommentSize];
	[defaultValues setObject:[NSNumber numberWithInt:1] forKey:ProVocCardDisplayImages];
	[defaultValues setObject:[NSNumber numberWithFloat:0.5] forKey:ProVocCardImageFraction];
	value = [defaults objectForKey:@"PVCardWidth"];
	if (!value)
		value = [NSNumber numberWithFloat:241];
	[defaultValues setObject:value forKey:ProVocCardWidth];
	[defaultValues setObject:value forKey:ProVocCardCustomWidth];
	value = [defaults objectForKey:@"PVCardHeight"];
	if (!value)
		value = [NSNumber numberWithFloat:153];
	[defaultValues setObject:value forKey:ProVocCardHeight];
	[defaultValues setObject:value forKey:ProVocCardCustomHeight];
	value = [defaults objectForKey:@"PVFlipCardVertically"];
	[defaultValues setObject:value ? value : [NSNumber numberWithInt:0] forKey:ProVocCardFlipDirection];
	value = [defaults objectForKey:@"printFontColor"];
	[defaultValues setObject:value ? value : [NSArchiver archivedDataWithRootObject:[NSColor blackColor]] forKey:ProVocCardTextColor];
	value = [defaults objectForKey:@"printBackgroundColor"];
	[defaultValues setObject:value ? value : [NSArchiver archivedDataWithRootObject:[NSColor whiteColor]] forKey:ProVocCardBackgroundColor];
	[defaultValues setObject:[NSNumber numberWithFloat:0.0] forKey:@"cardLeftMargin"];
	[defaultValues setObject:[NSNumber numberWithFloat:0.0] forKey:@"cardTopMargin"];
	[defaultValues setObject:[NSNumber numberWithFloat:0.0] forKey:@"cardRightMargin"];
	[defaultValues setObject:[NSNumber numberWithFloat:0.0] forKey:@"cardBottomMargin"];

    [defaultValues setObject:[NSNumber numberWithInt:0] forKey:PVSizeUnit];
    [defaultValues setObject:[NSNumber numberWithInt:0] forKey:ProVocCardFormat];
    [defaultValues setObject:[NSNumber numberWithInt:0] forKey:ProVocCardTagDisplay];
	[defaultValues setObject:[NSNumber numberWithFloat:0.5] forKey:ProVocCardTagFraction];
    [defaultValues setObject:[NSNumber numberWithFloat:[NSFont systemFontSize]] forKey:PVPrintListFontSize];
	
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:PVDimTestBackground];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:PVFullScreenWithMenuBar];
    [defaultValues setObject:[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedWhite:0.2 alpha:1.0]] forKey:PVTestBackgroundColor];

    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:PVSearchSources];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:PVSearchTargets];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:PVSearchComments];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:@"autoCheckForUpdates"];
        
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:ProVocPrintComments];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:ProVocPrintPageNumbers];

    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:PVSlideshowAutoAdvance];
    [defaultValues setObject:[NSNumber numberWithFloat:0.5] forKey:PVSlideshowSpeed];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:PVSlideshowRandom];
	
    [defaultValues setObject:[[NSFont systemFontOfSize:0] familyName] forKey:@"sourceFontFamilyName"];
    [defaultValues setObject:[[NSFont systemFontOfSize:0] familyName] forKey:@"targetFontFamilyName"];
    [defaultValues setObject:[[NSFont systemFontOfSize:0] familyName] forKey:@"commentFontFamilyName"];
    [defaultValues setObject:[NSNumber numberWithFloat:[NSFont systemFontSize]] forKey:@"sourceFontSize"];
    [defaultValues setObject:[NSNumber numberWithFloat:[NSFont systemFontSize]] forKey:@"targetFontSize"];
    [defaultValues setObject:[NSNumber numberWithFloat:[NSFont systemFontSize]] forKey:@"commentFontSize"];
    [defaultValues setObject:[NSNumber numberWithInt:24] forKey:@"sourceTestFontSize"];
    [defaultValues setObject:[NSNumber numberWithInt:24] forKey:@"targetTestFontSize"];
    [defaultValues setObject:[NSNumber numberWithInt:18] forKey:@"commentTestFontSize"];
    [defaultValues setObject:[NSArchiver archivedDataWithRootObject:[NSColor darkGrayColor]] forKey:@"commentTextColor"];

    [defaultValues setObject:[NSNumber numberWithInt:NSWritingDirectionLeftToRight] forKey:@"sourceWritingDirection"];
    [defaultValues setObject:[NSNumber numberWithInt:NSWritingDirectionLeftToRight] forKey:@"targetWritingDirection"];
    [defaultValues setObject:[NSNumber numberWithInt:NSWritingDirectionLeftToRight] forKey:@"commentWritingDirection"];

    [defaultValues setObject:[NSNumber numberWithInt:0] forKey:PVExportFormat];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:PVExportComments];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:PVExportPageNames];
	
	NSArray *labels = [NSArray arrayWithObjects:
						[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Label 1 Default Title", @""), PVLabelTitle,
												[NSArchiver archivedDataWithRootObject:[NSColor redColor]], PVLabelColorData, nil],
						[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Label 2 Default Title", @""), PVLabelTitle,
												[NSArchiver archivedDataWithRootObject:[NSColor orangeColor]], PVLabelColorData, nil],
						[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Label 3 Default Title", @""), PVLabelTitle,
												[NSArchiver archivedDataWithRootObject:[NSColor yellowColor]], PVLabelColorData, nil],
						[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Label 4 Default Title", @""), PVLabelTitle,
												[NSArchiver archivedDataWithRootObject:[NSColor greenColor]], PVLabelColorData, nil],
						[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Label 5 Default Title", @""), PVLabelTitle,
												[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.0 green:0.5 blue:0.0 alpha:1.0]], PVLabelColorData, nil],
						[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Label 6 Default Title", @""), PVLabelTitle,
												[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.5 green:0.75 blue:1.0 alpha:1.0]], PVLabelColorData, nil],
						[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Label 7 Default Title", @""), PVLabelTitle,
												[NSArchiver archivedDataWithRootObject:[NSColor blueColor]], PVLabelColorData, nil],
						[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Label 8 Default Title", @""), PVLabelTitle,
												[NSArchiver archivedDataWithRootObject:[NSColor purpleColor]], PVLabelColorData, nil],
						[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Label 9 Default Title", @""), PVLabelTitle,
												[NSArchiver archivedDataWithRootObject:[NSColor grayColor]], PVLabelColorData, nil],
						nil];
						
	[defaultValues setObject:[NSNumber numberWithInt:0] forKey:iPodPagesToSend];
	[defaultValues setObject:[NSNumber numberWithInt:1] forKey:iPodContentToSend];
	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:iPodSinglePageNotes];
	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:iPodAllowOtherNotes];
	
	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:PVMarkWrongWords];
	[defaultValues setObject:[NSNumber numberWithInt:0] forKey:PVLabelForWrongWords];
	[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:PVSlideShowWithWrongWords];

	[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:PVBackTranslationWithAllWords]; // Hidden pref

	[defaultValues setObject:[NSNumber numberWithBool:[ProVocBackground isAvailable]] forKey:PVEnableBackground];
    [defaultValues setObject:[NSNumber numberWithFloat:60] forKey:@"AutosavingDelay"];
	
	[defaultValues setObject:labels forKey:PVLabels];

    NSString *path = [[NSBundle mainBundle] pathForResource:@"Languages" ofType:@"xml" inDirectory:@""];
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    [defaultValues setObject:dictionary forKey:PVPrefsLanguages];
	
	[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:ProVocShowStartingPoint];

    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];

    ARUpdateManager *updater = [ARUpdateManager sharedManager];
	[updater setIsSoftwareUpdate:YES];
	[updater setServerName:@"www.arizona-software.ch"];
	[updater setServerPath:@"/updates/"];
//    [updater setLocalPath:[[[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist" inDirectory:@"Updates"] stringByDeletingLastPathComponent]];
    [updater setName:@"provoc"];
	[updater setUpdateBlacklist:YES];
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"Updated To 2.7"]) {
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Updated To 2.7"];
		[updater setAutoCheck:YES];
	}
	[updater insertPreferencesIntoView:[[ProVocPreferences sharedPreferences] updateView]];
}

-(void)awakeFromNib
{
	if ([NSApp systemVersion] >= 0x1040)
		[[NSDocumentController sharedDocumentController] setAutosavingDelay:[[NSUserDefaults standardUserDefaults] floatForKey:@"AutosavingDelay"]];
	[[ARAboutDialog sharedAboutDialog] show:nil];
	[[NSUserDefaults standardUserDefaults] upgrade];
	[[ARAboutDialog sharedAboutDialog] performSelector:@selector(hide:) withObject:nil afterDelay:3.0];
	[iPodManager sharedManager];
}

-(void)applicationDidFinishLaunching:(NSNotification *)inNotification
{
	ProVocServiceProvider *serviceProvider = [[ProVocServiceProvider alloc] init];
	[NSApp setServicesProvider:serviceProvider];
	
	if ([NSApp systemVersion] >= 0x1040 && ![[NSFileManager defaultManager] fileExistsAtPath:[@"~/Library/Widgets/ProVoc.wdgt" stringByExpandingTildeInPath]]
				&& ![[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Widgets/ProVocs.wdgt"] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"IgnoreWidgetInstall"]
				&& [[[NSDocumentController sharedDocumentController] recentDocumentURLs] count] > 0) {
		NSString *check = [NSString stringWithContentsOfURL:[NSURL URLWithString:NSLocalizedString(@"Install Widget Check URL", @"")]];
		if ([check isEqual:@"OK"]) {
			int result = NSRunAlertPanel(NSLocalizedString(@"Install Widget Title", @""), NSLocalizedString(@"Install Widget Message", @""),
					NSLocalizedString(@"Install Widget Download Button", @""), NSLocalizedString(@"Install Widget Later Button", @""), NSLocalizedString(@"Install Widget Ignore Button", @""));
			switch (result) {
				case NSAlertDefaultReturn:
					[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"Widget Download URL", @"")]];
					break;
				case NSAlertAlternateReturn:
					break;
				case NSAlertOtherReturn:
					[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"IgnoreWidgetInstall"];
					break;
			}
		}
	}
}

- (IBAction)showPreferences:(id)sender
{
    [[ProVocPreferences sharedPreferences] showWindow:self];
}

/*
-(IBAction)showHelp:(id)inSender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.arizona-software.ch/provoc/help"]];
}
*/

-(IBAction)checkForUpdates:(id)inSender
{
    [[ARUpdateManager sharedManager] checkForUpdates:inSender];
}

-(BOOL)applicationShouldOpenUntitledFile:(NSApplication *)inSender
{
	static BOOL first = YES;
	if (first) {
		first = NO;
//		switch ([[NSUserDefaults standardUserDefaults] integerForKey:@"StartBehavior"]) {
		switch (1) {
			case 0: // Create New Document
				return YES;
			case 1: { // Open Last Document 
				NSArray *recentURLs = [self recentDocumentURLs];
				if ([recentURLs count] > 0) {
					NSString *path = [[recentURLs objectAtIndex:0] path];
					if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
						if ([self openDocumentWithContentsOfFile:path display:YES])
							return NO;
					}
				}
				[[ProVocStartingPoint defaultStartingPoint] idle];
				return NO;
				break;
			} case 2: // Don't Open any Document
				return NO;
		}
	}
	return YES;
}

-(id)openDocumentWithContentsOfURL:(NSURL *)inURL display:(BOOL)inDisplay error:(NSError **)outError
{
	id document = [super openDocumentWithContentsOfURL:inURL display:inDisplay error:outError];
	NSAppleEventDescriptor *lastEvent = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
	NSString *searchString = [[lastEvent descriptorForKeyword:keyAESearchText] stringValue];
	if ([searchString length] > 0)
		[document setSpotlightSearch:searchString];
	return document;
}

-(IBAction)discoverProvoc:(id)inSender
{
	NSString *address = [NSString stringWithFormat:NSLocalizedString(@"Discover Features URL (v=%@)", @""), [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:address]];
}

-(IBAction)visitHomepage:(id)inSender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"Homepage URL", @"")]];
}

-(IBAction)reportBug:(id)inSender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"Bug Report URL", @"")]];
}

-(IBAction)downloadDocuments:(id)inSender
{
	NSString *address = [NSString stringWithFormat:NSLocalizedString(@"Download Vocabulary URL (v=%@)", @""), [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:address]];
}

-(void)submitDocument:(id)inSender
{
}

-(IBAction)toggleInspector:(id)inSender
{
	[[ProVocInspector sharedInspector] toggle];
}

-(BOOL)validateMenuItem:(NSMenuItem *)inItem
{
	SEL action = [inItem action];
	if (action == @selector(toggleInspector:))
		[inItem setState:[[ProVocInspector sharedInspector] isVisible] ? NSOnState : NSOffState];
	if (action == @selector(submitDocument:)) {
		[inItem setTitle:NSLocalizedString(@"Submit Document", @"")];
		return NO;
	}
	return [super validateMenuItem:inItem];
}

-(void)removeDocument:(NSDocument *)inDocument
{
	[NSObject cancelPreviousPerformRequestsWithTarget:inDocument];
	[[NSRunLoop currentRunLoop] cancelPerformSelectorsWithTarget:inDocument];
    [[NSNotificationCenter defaultCenter] removeObserver:inDocument];
	[super removeDocument:inDocument];
}

-(void)applicationDidBecomeActive:(NSNotification *)inNotification
{
	[[self documents] makeObjectsPerformSelector:@selector(checkWidgetLog)];
}

@end

@implementation NSApplication (About)

-(void)orderFrontStandardAboutPanel:(id)inSender
{
	[[ARAboutDialog sharedAboutDialog] showAboutWindow];
}

@end

@implementation NSUserDefaults (Upgrade)

-(void)upgrade
{
	if (![self boolForKey:@"Upgraded to v4.0"]) {
		[self setBool:YES forKey:@"Upgraded to v4.0"];
		id familyName = [self objectForKey:@"fontFamilyName"];
		if (familyName) {
			[self setObject:familyName forKey:@"sourceFontFamilyName"];
			[self setObject:familyName forKey:@"targetFontFamilyName"];
			[self setObject:familyName forKey:@"commentFontFamilyName"];
		}

		id fontSize = [self objectForKey:@"fontSize"];
		if (fontSize) {
			[self setObject:fontSize forKey:@"sourceFontSize"];
			[self setObject:fontSize forKey:@"targetFontSize"];
		}

		fontSize = [self objectForKey:@"questionFontSize"];
		if (fontSize) {
			[self setObject:fontSize forKey:@"sourceTestFontSize"];
			[self setObject:fontSize forKey:@"targetTestFontSize"];
		}

		fontSize = [self objectForKey:@"commentFontSize"];
		if (fontSize && ![self objectForKey:@"commentTestFontSize"]) {
		    [self setObject:fontSize forKey:@"commentTestFontSize"];
		    [self setObject:[NSNumber numberWithFloat:[NSFont systemFontSize]] forKey:@"commentFontSize"];
		}
	}
}

@end

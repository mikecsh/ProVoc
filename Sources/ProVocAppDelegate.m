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
#import "ProVocInspector.h"
#import "ProVocBackground.h"
#import "ProVocStartingPoint.h"
#import "ProVocCardController.h"
#import "ProVocServiceProvider.h"

#import "ARAboutDialog.h"

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
    
    defaultValues[@"translationCaption"] = @"";
    defaultValues[@"Image MCQ Line Height"] = @150.0f;
	
    defaultValues[PVPrefsUseSynonymSeparator] = @YES;
    defaultValues[PVPrefSynonymSeparator] = @"/";
	defaultValues[PVPrefTestSynonymsSeparately] = @YES;
    defaultValues[PVPrefsUseCommentsSeparator] = @NO;
    defaultValues[PVPrefCommentsSeparator] = @";";
    defaultValues[PVPrefsRightRatio] = @2.0f;

    defaultValues[PVLearnedConsecutiveRepetitions] = @2;
    defaultValues[PVLearnedDistractInterval] = @2;
	
    defaultValues[PVReviewLearningFactor] = @50.0f;
    defaultValues[PVReviewTrainingFactor] = @50.0f;
	
	id value;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	defaultValues[ProVocCardDisplayFrames] = @YES;
	defaultValues[ProVocCardPaperSides] = @2;
	defaultValues[ProVocCardTextSize] = @1.0f;
	defaultValues[ProVocCardDisplayComments] = @0;
	defaultValues[ProVocCardCommentSize] = @1.0f;
	defaultValues[ProVocCardDisplayImages] = @1;
	defaultValues[ProVocCardImageFraction] = @0.5f;
	value = [defaults objectForKey:@"PVCardWidth"];
	if (!value)
		value = @241.0f;
	defaultValues[ProVocCardWidth] = value;
	defaultValues[ProVocCardCustomWidth] = value;
	value = [defaults objectForKey:@"PVCardHeight"];
	if (!value)
		value = @153.0f;
	defaultValues[ProVocCardHeight] = value;
	defaultValues[ProVocCardCustomHeight] = value;
	value = [defaults objectForKey:@"PVFlipCardVertically"];
	defaultValues[ProVocCardFlipDirection] = value ? value : @0;
	value = [defaults objectForKey:@"printFontColor"];
	defaultValues[ProVocCardTextColor] = value ? value : [NSArchiver archivedDataWithRootObject:[NSColor blackColor]];
	value = [defaults objectForKey:@"printBackgroundColor"];
	defaultValues[ProVocCardBackgroundColor] = value ? value : [NSArchiver archivedDataWithRootObject:[NSColor whiteColor]];
	defaultValues[@"cardLeftMargin"] = @0.0f;
	defaultValues[@"cardTopMargin"] = @0.0f;
	defaultValues[@"cardRightMargin"] = @0.0f;
	defaultValues[@"cardBottomMargin"] = @0.0f;

    defaultValues[PVSizeUnit] = @0;
    defaultValues[ProVocCardFormat] = @0;
    defaultValues[ProVocCardTagDisplay] = @0;
	defaultValues[ProVocCardTagFraction] = @0.5f;
    defaultValues[PVPrintListFontSize] = [NSNumber numberWithFloat:[NSFont systemFontSize]];
	
    defaultValues[PVDimTestBackground] = @YES;
    defaultValues[PVFullScreenWithMenuBar] = @NO;
    defaultValues[PVTestBackgroundColor] = [NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedWhite:0.2 alpha:1.0]];

    defaultValues[PVSearchSources] = @YES;
    defaultValues[PVSearchTargets] = @YES;
    defaultValues[PVSearchComments] = @NO;
    defaultValues[@"autoCheckForUpdates"] = @YES;
        
    defaultValues[ProVocPrintComments] = @NO;
    defaultValues[ProVocPrintPageNumbers] = @NO;

    defaultValues[PVSlideshowAutoAdvance] = @YES;
    defaultValues[PVSlideshowSpeed] = @0.5f;
    defaultValues[PVSlideshowRandom] = @NO;
	
    defaultValues[@"sourceFontFamilyName"] = [[NSFont systemFontOfSize:0] familyName];
    defaultValues[@"targetFontFamilyName"] = [[NSFont systemFontOfSize:0] familyName];
    defaultValues[@"commentFontFamilyName"] = [[NSFont systemFontOfSize:0] familyName];
    defaultValues[@"sourceFontSize"] = [NSNumber numberWithFloat:[NSFont systemFontSize]];
    defaultValues[@"targetFontSize"] = [NSNumber numberWithFloat:[NSFont systemFontSize]];
    defaultValues[@"commentFontSize"] = [NSNumber numberWithFloat:[NSFont systemFontSize]];
    defaultValues[@"sourceTestFontSize"] = @24;
    defaultValues[@"targetTestFontSize"] = @24;
    defaultValues[@"commentTestFontSize"] = @18;
    defaultValues[@"commentTextColor"] = [NSArchiver archivedDataWithRootObject:[NSColor darkGrayColor]];

    defaultValues[@"sourceWritingDirection"] = @(NSWritingDirectionLeftToRight);
    defaultValues[@"targetWritingDirection"] = @(NSWritingDirectionLeftToRight);
    defaultValues[@"commentWritingDirection"] = @(NSWritingDirectionLeftToRight);

    defaultValues[PVExportFormat] = @0;
    defaultValues[PVExportComments] = @YES;
    defaultValues[PVExportPageNames] = @YES;
	
	NSArray *labels = @[@{PVLabelTitle: NSLocalizedString(@"Label 1 Default Title", @""),
												PVLabelColorData: [NSArchiver archivedDataWithRootObject:[NSColor redColor]]},
						@{PVLabelTitle: NSLocalizedString(@"Label 2 Default Title", @""),
												PVLabelColorData: [NSArchiver archivedDataWithRootObject:[NSColor orangeColor]]},
						@{PVLabelTitle: NSLocalizedString(@"Label 3 Default Title", @""),
												PVLabelColorData: [NSArchiver archivedDataWithRootObject:[NSColor yellowColor]]},
						@{PVLabelTitle: NSLocalizedString(@"Label 4 Default Title", @""),
												PVLabelColorData: [NSArchiver archivedDataWithRootObject:[NSColor greenColor]]},
						@{PVLabelTitle: NSLocalizedString(@"Label 5 Default Title", @""),
												PVLabelColorData: [NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.0 green:0.5 blue:0.0 alpha:1.0]]},
						@{PVLabelTitle: NSLocalizedString(@"Label 6 Default Title", @""),
												PVLabelColorData: [NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.5 green:0.75 blue:1.0 alpha:1.0]]},
						@{PVLabelTitle: NSLocalizedString(@"Label 7 Default Title", @""),
												PVLabelColorData: [NSArchiver archivedDataWithRootObject:[NSColor blueColor]]},
						@{PVLabelTitle: NSLocalizedString(@"Label 8 Default Title", @""),
												PVLabelColorData: [NSArchiver archivedDataWithRootObject:[NSColor purpleColor]]},
						@{PVLabelTitle: NSLocalizedString(@"Label 9 Default Title", @""),
												PVLabelColorData: [NSArchiver archivedDataWithRootObject:[NSColor grayColor]]}];
	
	defaultValues[PVMarkWrongWords] = @NO;
	defaultValues[PVLabelForWrongWords] = @0;
	defaultValues[PVSlideShowWithWrongWords] = @YES;

	defaultValues[PVBackTranslationWithAllWords] = @YES; // Hidden pref

	defaultValues[PVEnableBackground] = @([ProVocBackground isAvailable]);
    defaultValues[@"AutosavingDelay"] = @60.0f;
	
	defaultValues[PVLabels] = labels;

    NSString *path = [[NSBundle mainBundle] pathForResource:@"Languages" ofType:@"xml" inDirectory:@""];
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    defaultValues[PVPrefsLanguages] = dictionary;
	
	defaultValues[ProVocShowStartingPoint] = @YES;

    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
}

-(void)awakeFromNib
{
	if ([NSApp systemVersion] >= 0x1040)
		[[NSDocumentController sharedDocumentController] setAutosavingDelay:[[NSUserDefaults standardUserDefaults] floatForKey:@"AutosavingDelay"]];
	[[ARAboutDialog sharedAboutDialog] show:nil];
	[[NSUserDefaults standardUserDefaults] upgrade];
	[[ARAboutDialog sharedAboutDialog] performSelector:@selector(hide:) withObject:nil afterDelay:3.0];
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
    NSBeep();
    NSLog(@"%s - this should be removed, depend on App Store update mechanism instead", __func__);
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
					NSString *path = [recentURLs[0] path];
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
	NSString *address = [NSString stringWithFormat:NSLocalizedString(@"Discover Features URL (v=%@)", @""), [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"]];
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
	NSString *address = [NSString stringWithFormat:NSLocalizedString(@"Download Vocabulary URL (v=%@)", @""), [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"]];
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

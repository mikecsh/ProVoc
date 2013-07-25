//
//  ProVocPreferences.h
//  ProVoc
//
//  Created by bovet on Mon Feb 10 2003.
//  Copyright (c) 2003 Arizona Software. All rights reserved.
//

#import <AppKit/AppKit.h>

#define PVPrefsUseSynonymSeparator @"PVPrefsUseSynonymSeparator"
#define PVPrefSynonymSeparator @"PVPrefSynonymSeparator"
#define PVPrefTestSynonymsSeparately @"testSynonymsSeparately"
#define PVPrefsUseCommentsSeparator @"PVPrefsUseCommentsSeparator"
#define PVPrefCommentsSeparator @"PVPrefCommentsSeparator"
#define PVPrefsLanguages @"PVPrefsLanguagesV2"
#define PVPrefsRightRatio @"PVPrefsRightRatio"

#define PVLanguagePrefsDidChangeNotification @"PVLanguagePrefsDidChangeNotification"
#define PVLanguageNamesDidChangeNotification @"PVLanguageNamesDidChangeNotification"
#define PVRightRatioDidChangeNotification @"PVRightRatioDidChangeNotification"
#define PVReviewFactorDidChangeNotification @"PVReviewFactorDidChangeNotification"

#define PVCaseSensitive @"CaseSensitive"
#define PVAccentSensitive @"AccentSensitive"
#define PVPunctuationSensitive @"PunctuationSensitive"
#define PVSpaceSensitive @"SpaceSensitive"

#define PVLabels @"Labels"
#define PVLabelTitle @"Title"
#define PVLabelColorData @"ColorData"

@interface ProVocPreferences : NSWindowController
{
	IBOutlet NSView *mGeneralView;
	IBOutlet NSView *mLanguageView;
	IBOutlet NSView *mFontView;
	IBOutlet NSView *mLabelView; 
	IBOutlet NSView *mUpdateView;
	IBOutlet NSView *mTrainingView;
	
    IBOutlet NSTableView *mLanguageTableView;
	
	IBOutlet NSWindow *mLanguageOptionsWindow;

	NSArray *mPaneViews;
	NSArray *mPaneImageNames;
	NSArray *mPaneLabels;
	
}
+ (ProVocPreferences*)sharedPreferences;
- (IBAction)updateDifficulty:(id)sender;

-(IBAction)restoreDefaultLabels:(id)inSender;

-(void)openGeneralView:(id)inSender;

@end

@interface ProVocPreferences (Languages)

-(void)openLanguageView:(id)inSender;
- (NSMutableArray *)languages;
- (void)addLanguage:(NSDictionary *)inSettings;
- (IBAction)newLanguage:(id)sender;

-(IBAction)languageOptions:(id)inSender;
-(IBAction)confirmLanguageOptions:(id)inSender;

- (void)currentDocumentDidChange;

@end

@interface ProVocPreferences (Panes)

-(void)selectPaneAtIndex:(unsigned)inIndex;
-(void)setupToolbar;
-(NSView *)updateView;

@end

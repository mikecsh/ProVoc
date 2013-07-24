//
//  ProVocDocument+Lists.h
//  ProVoc
//
//  Created by Simon Bovet on 31.10.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ProVocDocument.h"
#import "ProVocPage.h"

#define PVSearchSources @"PVSearchSources"
#define PVSearchTargets @"PVSearchTargets"
#define PVSearchComments @"PVSearchComments"

#define ProVocSourcesType @"ProVocSourcesType"
#define ProVocSelfSourcesType [NSString stringWithFormat:@"ProVocSelfSourcesType%i", (int)self]
#define ProVocWordsType @"ProVocWordsType"
#define ProVocSelfWordsType [NSString stringWithFormat:@"ProVocSelfWordsType%i", (int)self]

@interface ProVocDocument (Words)

-(BOOL)canAddWord;

-(void)updateDifficultyLimits;

-(NSArray *)allWords;
-(NSArray *)selectedWords;

-(NSArray *)wordsInPages:(NSArray *)inPages;

-(void)wordsDidChange;
-(void)sortedWordsDidChange;
-(void)visibleWordsDidChange;

-(void)deleteWords:(NSArray *)inWords;

-(void)cancelDoubleWordSearch;
-(id)doubleWordsIn:(NSArray *)inWords progressDelegate:(id)inDelegate;

-(void)keepSelectedWords;
-(void)keepWordsSelected:(NSArray *)inWords;

@end

@interface ProVocDocument (Sort)

-(void)sortWords:(NSMutableArray *)inWords;
-(void)sortWords:(NSMutableArray *)inWords sortIdentifier:(id)inSortIdentifier;
-(void)sortWordsByColumn:(NSTableColumn *)inTableColumn;
-(NSArray *)determinentsOfLanguageWithIdentifier:(id)inIdentifier ignoreCase:(BOOL *)outIgnoreCase ignoreAccents:(BOOL *)outIgnoreAccents;

@end

@interface ProVocDocument (AutoSizeColumns)

-(void)tableView:(NSTableView *)inTableView autoSizeTableColumn:(NSTableColumn *)inTableColumn;

@end

@interface ProVocDocument (Search)

-(BOOL)doesWord:(ProVocWord *)inWord containString:(NSString *)inSearchString;
-(void)showAllWords;
-(BOOL)showingAllWords;

-(void)revealSelectedWordsInPages:(id)inSender;
-(void)revealWordsInPages:(NSArray *)inWords;

@end

@interface ProVocDocument (Pages)

-(void)pagesDidChange;
-(void)selectedPagesDidChange;

-(NSArray *)selectedSourceAncestors;
-(NSArray *)selectedPages;
-(ProVocPage *)currentPage;
-(NSArray *)allPages;

-(void)rightRatioDidChange:(NSNotification *)inNotification;

@end

@interface ProVocDocument (Languages)

-(void)updateLanguagePopUps;
-(void)languageNamesDidChange:(NSNotification *)inNotification;
-(void)languagesDidChange;

@end

@interface ProVocDocument (Encoding)

-(BOOL)useCustomEncoding;
-(NSStringEncoding)stringEncoding;

@end

@interface ProVocDocument (Labels)

-(NSColor *)colorForLabel:(int)inLabel;
+(NSImage *)imageForLabel:(int)inLabel;
-(NSImage *)imageForLabel:(int)inLabel;
-(NSImage *)imageForLabel:(int)inLabel flagged:(BOOL)inFlagged;
-(NSString *)stringForLabel:(int)inLabel;

+(void)labelColorsDidChange;
+(void)labelTitlesDidChange;
-(void)updateTestOnlyPopUpMenu;

@end

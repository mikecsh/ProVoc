//
//  ProVocCardsView.h
//  ProVoc
//
//  Created by Simon Bovet on 25.04.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ProVocDocument.h"

#define ProVocCardPaperSides @"cardPaperSides"
#define ProVocCardFlipDirection @"cardFlipDirection"
#define ProVocCardWidth @"cardWidth"
#define ProVocCardHeight @"cardHeight"
#define ProVocCardTextColor @"cardTextColor"
#define ProVocCardTextSize @"cardTextSize"
#define ProVocCardBackgroundColor @"cardBackgroundColor"
#define ProVocCardDisplayComments @"cardDisplayComments"
#define ProVocCardCommentSize @"cardCommentSize"
#define ProVocCardDisplayImages @"cardDisplayImages"
#define ProVocCardTagDisplay @"cardDisplayTag"
#define ProVocCardTagFraction @"cardTagFraction"
#define ProVocCardImageFraction @"cardImageFraction"
#define ProVocCardDisplayFrames @"cardDisplayFrames"

@interface ProVocCardsView : NSView {
	ProVocDocument *mDocument;
	int mPaperSides;
	float mFontSizeFactor;
	BOOL mFlipVertically;
	NSArray *mWords;
	int mPages, mColumns, mRows;
	NSSize mCardSize;
	NSSize mPaperSize;
	NSRect mPaperBounds;
}

-(id)initWithDocument:(ProVocDocument *)inDocument words:(NSArray *)inWords;

+(void)drawCardString:(NSMutableAttributedString *)string
		withFontFamilyName:(NSString *)fontFamilyName fontSize:(float)fontSize
		forRecto:(BOOL)inRecto ofWord:(ProVocWord *)inWord ofDocument:(ProVocDocument *)inDocument inRect:(NSRect)rect;

@end

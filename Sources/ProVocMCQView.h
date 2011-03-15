//
//  ProVocMCQView.h
//  ProVoc
//
//  Created by Simon Bovet on 06.10.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ProVocMCQView : NSControl {
	IBOutlet id mDelegate;
	
	int mColumns;
	int mRows;
	NSArray *mAnswers;
	NSMutableDictionary *mSounds;
	NSMutableDictionary *mImages;
	NSMutableDictionary *mMovies;
	int mSelectedIndex;
	int mSolutionIndex;
	BOOL mShowSolution;
	BOOL mDisplayAnswers;
	NSSound *mCurrentSound;
	int mCurrentSoundIndex;
	
	id mTarget;
	SEL mAction;
}

-(int)columns;
-(void)setColumns:(int)inColumns;
-(int)rows;
-(void)setAnswers:(NSArray *)inAnswers solution:(id)inSolution;
-(void)showSolution:(id)inSender;
-(void)setDisplayAnswers:(BOOL)inDisplay;

-(BOOL)isAnswerCorrect;
-(NSString *)selectedAnswer;

-(float)preferredHeightForNumberOfAnswers:(int)inNumber;
-(void)stopMedia;

-(void)playSound;

@end

@interface NSObject (ProVocMCQViewDelegate)

-(BOOL)MCQView:(ProVocMCQView *)inView shouldSelectAnswer:(id)inAnswer;
-(NSString *)stringForAnswer:(id)inAnswer;
-(NSSound *)soundForAnswer:(id)inAnswer;
-(BOOL)autoPlaySound;
-(NSImage *)imageForAnswer:(id)inAnswer;
-(id)movieForAnswer:(id)inAnswer;

@end

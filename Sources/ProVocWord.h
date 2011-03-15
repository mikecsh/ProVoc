//
//  ProVocWord.h
//  ProVoc
//
//  Created by bovet on Sat Feb 08 2003.
//  Copyright (c) 2003 Arizona Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ProVocPage;

@interface ProVocWord : NSObject <NSCoding, NSCopying>
{
    ProVocPage *mPage;
    int mNumber;
    NSString *mSourceWord;
    NSString *mTargetWord;
    NSString *mComment;
    int mRight;
    int mWrong;
	float mDifficulty;
    int mMark;
	int mLabel;
	BOOL mIsDouble;
	
	int mIndexInFile;
	
	NSMutableDictionary *mMedia;
	NSDate *mLastAnswered;
}

-(void)setSourceWord:(NSString *)inSource;
-(void)setTargetWord:(NSString *)inTarget;
-(void)setComment:(NSString *)inTarget;
-(NSString *)sourceWord;
-(NSString *)targetWord;
-(NSString *)comment;
-(int)mark;
-(void)setMark:(int)inMark;
-(int)label;
-(void)setLabel:(int)inLabel;

-(void)swapSourceAndTarget:(id)inSender;

-(void)increaseDifficulty;
-(void)decreaseDifficulty;
-(void)resetDifficulty;
-(void)reset;
-(int)right;
-(int)wrong;
-(void)incrementRight;
-(void)incrementWrong;

-(NSDate *)lastAnswered;
-(void)resetLastAnswered;

-(NSDate *)nextReview;
-(NSTimeInterval)reviewInterval;

-(int)number;
-(void)setNumber:(int)inNumber;

-(int)indexInFile;
-(void)setIndexInFile:(int)inIndex;
-(void)resetIndexInFile;

-(ProVocPage *)page;
-(void)setPage:(ProVocPage *)inPage;
-(void)removeFromParent;

-(float)difficulty;

-(BOOL)isDouble;
-(void)setDouble:(id)inValue;

@end

@interface ProVocWord (Content)

-(id)objectForIdentifier:(id)inIdentifier;
-(void)setObject:(id)inObject forIdentifier:(id)inIdentifier;
-(id)valueForIdentifier:(id)inIdentifier;

@end

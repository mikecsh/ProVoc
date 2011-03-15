//
//  ProVocData.h
//  ProVoc
//
//  Created by bovet on Sun Feb 09 2003.
//  Copyright (c) 2003 Arizona Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ProVocChapter;

@interface ProVocData : NSObject <NSCoding> {
	ProVocChapter *mRootChapter;

    NSString *mSourceLanguage;
    NSString *mTargetLanguage;
}

-(ProVocChapter *)rootChapter;
-(NSArray *)allPages;
-(NSArray *)allWords;

@end

@interface ProVocData (Language)

-(void)setSourceLanguage:(NSString*)language;
-(void)setTargetLanguage:(NSString*)language;
-(NSString *)sourceLanguage;
-(NSString *)targetLanguage;

@end

@interface ProVocSource : NSObject <NSCoding> {
	id mParent;
    NSString *mTitle;
}

-(id)parent;
-(void)setParent:(id)inParent;
-(void)removeFromParent;

-(NSString *)title;
-(void)setTitle:(NSString *)inTitle;

@end

@interface NSArray (ProVocSource)

-(NSArray *)commonAncestors;
-(BOOL)containsDescendant:(ProVocSource *)inSource;

@end

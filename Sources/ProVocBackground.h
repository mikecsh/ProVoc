//
//  ProVocBackground.h
//  ProVoc
//
//  Created by Simon Bovet on 23.04.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <Quartz/Quartz.h>

#define PVEnableBackground @"enableBackground"

@class ProVocBackgroundStyle;

@interface ProVocBackground : NSWindowController {
	IBOutlet QCView *mView;
	NSWindow *mWindow;
	NSMutableArray *mInputsToTrigger;
	BOOL mDisplayed;
}

+(BOOL)isAvailable;
+(ProVocBackground *)sharedBackground;

-(void)display;
-(void)hide;

-(void)setStyle:(ProVocBackgroundStyle *)inStyle;
-(void)setCompositionPath:(NSString *)inPath;
-(void)displayNow;

-(void)setValue:(id)inValue forInputKey:(NSString *)inKey;
-(void)setValue:(id)inValue forInputKeys:(NSArray *)inKeys;
-(void)triggerInputKey:(NSString *)inKey;
-(void)triggerInputKeys:(NSArray *)inKeys;

@end

@interface ProVocBackgroundStyle : NSObject {
	NSBundle *mBundle;
	NSString *mCompositionPath;
}

+(NSArray *)availableBackgroundStyles;
+(NSArray *)availableBackgroundStyleNames;

+(NSString *)customBackgroundCompositionPath;
+(void)setCustomBackgroundCompositionPath:(NSString *)inPath;

+(int)indexOfCurrentBackgroundStyle;
+(void)setIndexOfCurrentBackgroundStyle:(int)inIndex;

+(ProVocBackgroundStyle *)currentBackgroundStyle;
+(void)setCurrentBackgroundStyle:(ProVocBackgroundStyle *)inStyle;

+(id)backgroundStyleWithPath:(NSString *)inPath;
-(id)initWithPath:(NSString *)inPath;

+(id)backgroundStyleWithCompositionAtPath:(NSString *)inPath;
-(id)initWithCompositionAtPath:(NSString *)inPath;

-(id)identifier;
-(NSString *)compositionPath;
-(NSString *)name;

@end
//
//  iPodController.h
//  ProVoc
//
//  Created by Simon Bovet on 02.02.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ProVocDocument.h"
#import "ProVocData.h"
#import "ProVocMCQTester.h"

#define iPodPagesToSend @"pagesToSendToiPod"
#define iPodSinglePageNotes @"iPodSinglePageNotes"
#define iPodAllowOtherNotes @"allowOtheriPodNotes"
#define iPodContentToSend @"iPodContentToSend"

@interface iPodController : NSWindowController {
	ProVocDocument *mDocument;
	IBOutlet NSTabView *mTabView;
	BOOL mSending;
	BOOL mKeepOn;
	float mProgress;
	
	NSException *mException;
	NSMutableSet *mAudioToSendToiPod;
}

-(id)initWithDocument:(ProVocDocument *)inDocument;
-(void)send;

-(IBAction)cancel:(id)inSender;
-(IBAction)startSending:(id)inSender;
-(IBAction)confirm:(id)inSender; 
-(IBAction)eject:(id)inSender; 

@end

@interface iPodController (iPod)

+(NSString *)iPodNotePath;
+(NSString *)proVocIndexFile;
+(BOOL)updateiPodIndex;

+(BOOL)getiPodSysInfo:(NSString *)inKey value:(long long *)outValue visible:(NSString **)outVisible;
+(BOOL)isClickWheeliPod;
+(BOOL)is5GiPod:(float *)outVersion;

+(NSSet *)usedMedia;
-(void)sendAudioToiPod:(NSString *)inAudioPath;

@end

@interface ProVocDocument (iPod)

-(IBAction)sendToiPod:(id)inSender;
-(IBAction)displayiPodPreferences:(id)inSender;
-(IBAction)ejectiPod:(id)inSender;

@end

@interface NSObject (iPod)

-(NSString *)iPodFilename;

@end

@interface ProVocSource (iPod)

-(NSString *)iPodTitle;
-(NSArray *)iPodPathComponents;

@end

@interface iPodWord : NSObject {
	int mIndex;
	int mTotal;
	NSString *mTitleFormat;
	NSString *mQuestion;
	NSString *mComment;
	NSArray *mAnswers;
	NSArray *mNotes;
	NSString *mSolution;
	NSString *mQuestionAudio;
	NSString *mAnswerAudio;
	
	iPodWord *mNextWord;
}

-(id)initWithIndex:(int)inIndex total:(int)inTotal;

-(void)setQuestion:(NSString *)inQuestion;
-(void)setComment:(NSString *)inComment;
-(void)setAnswers:(NSArray *)inAnswers withNotes:(NSArray *)inNotes;
-(void)setSolution:(NSString *)inSolution;
-(void)setNextWord:(iPodWord *)inWord;
-(void)setQuestionAudio:(NSString *)inAudio;
-(void)setAnswerAudio:(NSString *)inAudio;

-(BOOL)send:(id)inSender;

@end

@interface iPodTester : ProVocMCQTester {
	iPodController *mController;
	NSMutableArray *miPodWords;
	iPodWord *mCurrentiPodWord;
	NSString *mDiskPath;
	NSString *mRefPath;
	NSMutableArray *mAnswers;
	int mTotal;
}

-(void)sendPage:(ProVocPage *)inPage withWords:(NSArray*)inWords parameters:(id)inParameters atPath:(NSString *)inPath relativeTo:(NSString *)inDiskRoot delegate:(id)inDelegate;

@end

@interface NSFileManager (FullDirectory)

-(BOOL)createFullDirectoryAtPath:(NSString *)inPath;

@end

@interface NSString (iPodController)

-(NSString *)iPodLinkString;
-(NSString *)iPodHTMLString;

@end

@interface iPodContent : NSObject {
	NSString *mPath;
	NSString *mName;
	NSMutableArray *mChildren;
	BOOL mExpandable;
	int mNumberOfWords;
	int mNumberOfNotes;
}

+(id)currentiPodContent;
-(id)initWithPath:(NSString *)inPath name:(NSString *)inName;

-(NSString *)path;
-(BOOL)isExpandable;
-(int)numberOfWords;
-(int)numberOfNotes;
-(NSString *)nameWithCountOf:(int)inWhat;
-(NSArray *)children;

@end

@interface NSScanner (iPod)

-(BOOL)scanTitle:(NSString **)outTitle;
-(BOOL)scanLinkWithRef:(NSString **)outRef name:(NSString **)outName;

@end

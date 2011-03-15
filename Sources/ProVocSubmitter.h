//
//  ProVocSubmitter.h
//  FTPTest
//
//  Created by Simon Bovet on 08.05.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ZIPCompresser.h"
#import "FTPUploader.h"

@interface ProVocSubmitter : NSWindowController {
	IBOutlet NSTabView *mTabView;
	
	NSString *mFile;
	ZIPCompresser *mCompresser;
	FTPUploader *mUploader;
	
	NSString *mTitle;
	NSString *mAuthor;
	NSString *mComments;
	NSString *progressLabel;
	float progress;
	BOOL indeterminateProgress;
	
	BOOL mAborting;
	NSString *mSubmissionIdentifier;
	NSString *mDestination;
	NSString *mConfirmationString;
	
	NSMutableDictionary *mInfo;
	
	id mDelegate;
}

-(void)setDelegate:(id)inDelegate;
-(void)submitFile:(NSString *)inFile
	sourceLanguage:(NSString *)inSourceLanguage
	targetLanguage:(NSString *)inTargetLanguage
	info:(NSDictionary *)inInfo
	modalForWindow:(NSWindow *)inWindow;

-(NSString *)title;
-(NSString *)author;
-(NSString *)comments;

@end

@interface NSObject (ProVocSubmitterDelegate)

-(void)submitter:(ProVocSubmitter *)inSubmitter updateSubmissionInfo:(NSDictionary *)inInfo;

@end

@interface ProVocSubmitter (Interface)

-(void)selectTabViewItemAtIndex:(int)inIndex;

-(IBAction)submit:(id)inSender;
-(IBAction)cancel:(id)inSender;
-(IBAction)abort:(id)inSender;
-(IBAction)close:(id)inSender;

@end
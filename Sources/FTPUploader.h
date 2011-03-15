//
//  FTPUploader.h
//  FTPTest
//
//  Created by Simon Bovet on 08.05.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FTPUploader : NSObject {
	NSString *mFile;
	unsigned long long mFileSize;
	unsigned long long mHashSize;
	unsigned long long mUploadedSize;
	
	NSTask *mTask;
	NSFileHandle *mTaskInput;
	NSMutableArray *mCommandBuffer;
	
	id mDelegate;
	BOOL mUploading;
}

-(id)initWithUser:(NSString *)inUser password:(NSString *)inPassword
		host:(NSString *)inHost path:(NSString *)inPath
		file:(NSString *)inFile;

-(void)setDelegate:(id)inDelegate;
-(void)startUpload;
-(void)cancelUpload;

@end

@interface NSObject (FTPUploaderDelegate)

-(void)uploader:(FTPUploader *)inUploader didFinishWithCode:(int)inCode;
-(void)uploader:(FTPUploader *)inUploader progress:(float)inProgress;

@end
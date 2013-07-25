//
//  FTPUploader.m
//  FTPTest
//
//  Created by Simon Bovet on 08.05.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "FTPUploader.h"


@implementation FTPUploader

-(id)initWithUser:(NSString *)inUser password:(NSString *)inPassword
		host:(NSString *)inHost path:(NSString *)inPath
		file:(NSString *)inFile
{
	if (self = [super init]) {
		mFile = [inFile retain];
		NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:mFile traverseLink:YES];
	    NSNumber *fileSize;
	    if (fileSize = fileAttributes[NSFileSize])
			mFileSize = [fileSize longLongValue];
		else {
			NSLog(@"*** FTPUploader Error: %@ doesn't exist", mFile);
			[self release];
			return nil;
		}
		mHashSize = 10 * 1024;

		mCommandBuffer = [[NSMutableArray alloc] initWithCapacity:1];
		
		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
		mTask = [[NSTask alloc] init];
		[center addObserver:self selector:@selector(taskCompleted:) name:NSTaskDidTerminateNotification object:mTask];
		[mTask setLaunchPath:@"/usr/bin/ftp"];
		[mTask setCurrentDirectoryPath:[inFile stringByDeletingLastPathComponent]];
		[mTask setArguments:@[@"-v",
                                [NSString stringWithFormat:@"ftp://%@:%@@%@/", inUser, inPassword,
                                                            [inHost stringByAppendingPathComponent:inPath]]]];

		NSPipe *inputPipe = [NSPipe pipe];
		NSFileHandle *taskInput = [inputPipe fileHandleForWriting];
		[center addObserver:self selector:@selector(connectionAccepted:) name:NSFileHandleConnectionAcceptedNotification object:taskInput];
		[mTask setStandardInput:inputPipe];

		NSPipe *outputPipe = [NSPipe pipe];
		NSFileHandle *taskOutput = [outputPipe fileHandleForReading];
		[center addObserver:self selector:@selector(taskDataAvailable:) name:NSFileHandleReadCompletionNotification object:taskOutput];
		[mTask setStandardOutput:outputPipe];

		NSPipe *errorPipe = [NSPipe pipe];
		NSFileHandle *errorOutput = [errorPipe fileHandleForReading];
		[center addObserver:self selector:@selector(taskErrorDataAvailable:) name:NSFileHandleReadCompletionNotification object:errorOutput];
		[mTask setStandardError:errorPipe];

		[mTask launch];
		[taskInput acceptConnectionInBackgroundAndNotify];
		[taskOutput readInBackgroundAndNotify];
		[errorOutput readInBackgroundAndNotify];
	}
	return self;
}

-(void)dealloc
{
	[mTask interrupt];
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[mFile release];
	[mTask release];
	[mTaskInput release];
	[mCommandBuffer release];

	[super dealloc];
}

-(void)sendCommand:(NSString *)inCommand
{
	if (!mTaskInput)
		[mCommandBuffer addObject:inCommand];
	else {
		NSString *command = [inCommand stringByAppendingString:@"\n"];
		[mTaskInput writeData:[command dataUsingEncoding:NSASCIIStringEncoding]];
	}
}

-(unsigned long long)hashSize
{
	return mHashSize;
}

-(void)countHashIn:(NSString *)inString
{
	int i, n = [inString length];
	int c = 0;
	for (i = 0; i < n; i++)
		if ([inString characterAtIndex:i] == '#')
			c++;
	if (c > 0) {
		mUploadedSize += c * mHashSize;
		[mDelegate uploader:self progress:(float)(mUploadedSize) / mFileSize];
	}
}

-(void)connectionAccepted:(NSNotification *)inNotification
{
    mTaskInput = [[inNotification object] retain];
	while ([mCommandBuffer count] > 0) {
		[self sendCommand:mCommandBuffer[0]];
		[mCommandBuffer removeObjectAtIndex:0];
	}
}

-(void)taskCompleted:(NSNotification *)inNotification
{
    [mTask waitUntilExit];
    int exitCode = [mTask terminationStatus];
	mUploading = NO;
	[mDelegate uploader:self didFinishWithCode:exitCode];
	[self autorelease];
}

-(void)taskDataAvailable:(NSNotification *)inNotification
{
    NSData *incomingData = [inNotification userInfo][NSFileHandleNotificationDataItem];
    if (incomingData && [incomingData length] > 0) {
        NSString *incomingText = [[[NSString alloc] initWithData:incomingData encoding:NSASCIIStringEncoding] autorelease];
		[self countHashIn:incomingText];
        [[inNotification object] readInBackgroundAndNotify];
    }
}

-(void)taskErrorDataAvailable:(NSNotification *)inNotification
{
    NSData *incomingData = [inNotification userInfo][NSFileHandleNotificationDataItem];
    if (incomingData && [incomingData length] > 0) {
        NSString *incomingText = [[[NSString alloc] initWithData:incomingData encoding:NSASCIIStringEncoding] autorelease];
		NSLog(@"*** FTPUploader Error: %@", incomingText);
        [[inNotification object] readInBackgroundAndNotify];
    }
}

-(void)setDelegate:(id)inDelegate
{
	mDelegate = inDelegate;
}

-(void)startUpload
{
	if (!mUploading) {
		[self retain];
		[self sendCommand:[NSString stringWithFormat:@"hash %lli", [self hashSize]]];
		[self sendCommand:[NSString stringWithFormat:@"put %@", [mFile lastPathComponent]]];
		[self sendCommand:@"quit"];
		mUploading = YES;
	}
}

-(void)cancelUpload
{
	if (mUploading)
		[mTask interrupt];
}

@end

@implementation NSObject (FTPUploaderDelegate)

-(void)uploader:(FTPUploader *)inUploader didFinishWithCode:(int)inCode
{
}

-(void)uploader:(FTPUploader *)inUploader progress:(float)inProgress
{
}

@end
//
//  ZIPCompresser.m
//  FTPTest
//
//  Created by Simon Bovet on 08.05.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ZIPCompresser.h"


@implementation ZIPCompresser

-(id)initWithFile:(NSString *)inFile destination:(NSString *)inDestination
{
	if (![[NSFileManager defaultManager] fileExistsAtPath:inFile]) {
		NSLog(@"*** ZIPCompresser Error: %@ doesn't exist", inFile);
		return nil;
	}
	if (self = [super init]) {
		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
		mTask = [[NSTask alloc] init];
		[center addObserver:self selector:@selector(taskCompleted:) name:NSTaskDidTerminateNotification object:mTask];
		[mTask setLaunchPath:@"/usr/bin/zip"];
		[mTask setCurrentDirectoryPath:[inFile stringByDeletingLastPathComponent]];
		[mTask setArguments:@[@"-r",
								inDestination,
								[inFile lastPathComponent]]];

		NSPipe *outputPipe = [NSPipe pipe];
		NSFileHandle *taskOutput = [outputPipe fileHandleForReading];
		[center addObserver:self selector:@selector(taskDataAvailable:) name:NSFileHandleReadCompletionNotification object:taskOutput];
		[mTask setStandardOutput:outputPipe];

		NSPipe *errorPipe = [NSPipe pipe];
		NSFileHandle *errorOutput = [errorPipe fileHandleForReading];
		[center addObserver:self selector:@selector(taskErrorDataAvailable:) name:NSFileHandleReadCompletionNotification object:errorOutput];
		[mTask setStandardError:errorPipe];

		[taskOutput readInBackgroundAndNotify];
		[errorOutput readInBackgroundAndNotify];
	}
	return self;
}

-(void)dealloc
{
	[mTask interrupt];
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[mTask release];

	[super dealloc];
}

-(void)taskCompleted:(NSNotification *)inNotification
{
    [mTask waitUntilExit];
    int exitCode = [mTask terminationStatus];
	[mDelegate compresser:self didFinishWithCode:exitCode];
	[self autorelease];
}

-(void)taskDataAvailable:(NSNotification *)inNotification
{
    NSData *incomingData = [inNotification userInfo][NSFileHandleNotificationDataItem];
    if (incomingData && [incomingData length] > 0) {
        // NSString *incomingText = [[[NSString alloc] initWithData:incomingData encoding:NSASCIIStringEncoding] autorelease];
		// NSLog(@"%@", incomingText);
        [[inNotification object] readInBackgroundAndNotify];
    }
}

-(void)taskErrorDataAvailable:(NSNotification *)inNotification
{
    NSData *incomingData = [inNotification userInfo][NSFileHandleNotificationDataItem];
    if (incomingData && [incomingData length] > 0) {
        NSString *incomingText = [[[NSString alloc] initWithData:incomingData encoding:NSASCIIStringEncoding] autorelease];
		NSLog(@"*** ZIPCompresser Error: %@", incomingText);
        [[inNotification object] readInBackgroundAndNotify];
    }
}

-(void)setDelegate:(id)inDelegate
{
	mDelegate = inDelegate;
}

-(void)startCompress
{
	if (![mTask isRunning]) {
		[self retain];
		[mTask launch];
	}
}

-(void)cancelCompress
{
	if ([mTask isRunning])
		[mTask interrupt];
}

@end

@implementation NSObject (ZIPCompresserDelegate)

-(void)compresser:(ZIPCompresser *)inCompresser didFinishWithCode:(int)inCode
{
}

@end
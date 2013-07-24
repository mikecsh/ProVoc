//
//  iPodManager.m
//  ProVoc
//
//  Created by Simon Bovet on 13.02.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "iPodManager.h"


@implementation iPodManager

+(iPodManager *)sharedManager
{
	static iPodManager *sharedManager = nil;
	if (!sharedManager)
		sharedManager = [[self alloc] init];
	return sharedManager;
}

-(id)init
{
	if (self = [super init]) {
		[self update:nil];
		NSNotificationCenter *notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
		[notificationCenter addObserver:self selector:@selector(update:) name:NSWorkspaceDidMountNotification object:nil];
		[notificationCenter addObserver:self selector:@selector(update:) name:NSWorkspaceDidUnmountNotification object:nil];
	}
	return self;
}

-(void)dealloc
{
	[miPodPath release];
	[mLockTask release];
	[super dealloc];
}

-(BOOL)deviceIsiPodAtPath:(NSString *)inPath
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[inPath stringByAppendingPathComponent:@"iPod_Control"]];
}

-(NSString *)pathOfConnectediPod
{
	NSEnumerator *enumerator = [[[NSWorkspace sharedWorkspace] mountedRemovableMedia] objectEnumerator];
	NSString *path;
	while (path = [enumerator nextObject])
		if ([self deviceIsiPodAtPath:path])	
			break;
	return path;
}

-(NSString *)iPodPath
{
	return miPodPath;
}

-(void)setiPodPath:(NSString *)iniPodPath
{
	if (![miPodPath isEqualToString:iniPodPath]) {
		[miPodPath release];
		miPodPath = [iniPodPath retain];
		[[NSNotificationCenter defaultCenter] postNotificationName:iPodDidChangeNotification object:nil];
	}
}

-(void)update:(id)inSender
{
	[self setiPodPath:[self pathOfConnectediPod]];
}

-(BOOL)lockiPod
{
	if (![self iPodPath])
		return NO;
	else {
		[mLockTask release];
		mLockTask = [[NSTask alloc] init];
		[mLockTask setLaunchPath:@"/bin/cat"];
		[mLockTask setCurrentDirectoryPath:[self iPodPath]];
		[mLockTask launch];
		return YES;
	}
}

-(void)unlockiPod
{
	if (mLockTask) {
		[mLockTask terminate];
		[mLockTask release];
		mLockTask = nil;
		[[NSNotificationCenter defaultCenter] postNotificationName:iPodDidChangeNotification object:nil];
	}
}

@end

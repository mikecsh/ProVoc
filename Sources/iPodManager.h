//
//  iPodManager.h
//  ProVoc
//
//  Created by Simon Bovet on 13.02.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define iPodDidChangeNotification @"iPodDidChangeNotification"

@interface iPodManager : NSObject {
	NSString *miPodPath;
	NSTask *mLockTask;
}

+(iPodManager *)sharedManager;

-(void)update:(id)inSender;

-(NSString *)iPodPath;

-(BOOL)lockiPod;
-(void)unlockiPod;

@end

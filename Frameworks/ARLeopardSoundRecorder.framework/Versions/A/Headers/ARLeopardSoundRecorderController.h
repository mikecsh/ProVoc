//
//  ARLeopardSoundRecorderController.h
//  ARLeopardSoundRecorder
//
//  Created by Simon Bovet on 31.03.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ARLeopardSoundRecorderController : NSWindowController {
	BOOL mHasRecordedSound;
	BOOL mDidStartRecord;
	NSSound *mPlayingSound;
	
	IBOutlet NSView *mSingleShotRecordView;
}

+(ARLeopardSoundRecorderController *)sharedController;

-(BOOL)runModal;
-(NSString *)recordedFile;

-(NSString *)singleShotRecord;

-(IBAction)record:(id)inSender;
-(IBAction)play:(id)inSender;
-(IBAction)close:(id)inSender;
-(IBAction)settings:(id)inSender;

@end

//
//  ARSequenceGrabber.h
//  ARSequenceGrabber
//
//  Created by Simon Bovet on 18.04.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CSGCamera, CSequenceGrabber;
@class QTMovie, ARMovieView;

@interface ARSequenceGrabber : NSWindowController {
	IBOutlet NSWindow *mImageCaptureWindow;
	IBOutlet NSImageView *mImageCaptureView;
	CSGCamera *mCamera;
	NSImage *mCapturedImage;
	BOOL mFreezeImage;
	int mCountdown;
	NSWindow *mFlashWindow;
	
	IBOutlet NSWindow *mMovieCaptureWindow;
	IBOutlet id *mMovieCaptureQuickDrawView; //NSQuickDrawView
	CSequenceGrabber *mSequenceGrabber;
	BOOL mCapturingMovie;
	BOOL mPreviewing;
	BOOL mHasCapturedMovie;
	QTMovie *mMovie;
	ARMovieView *mMovieView;
}

+(id)sharedGrabber;

@end

@interface ARSequenceGrabber (Image)

-(NSImage *)captureImage;

-(IBAction)captureImage:(id)inSender;
-(IBAction)cancelCapture:(id)inSender;
-(IBAction)closeImageCapture:(id)inSender;

@end

@interface ARSequenceGrabber (Movie)

-(NSString *)captureMovie;

-(IBAction)closeMovieCapture:(id)inSender;
-(IBAction)toggleMovieCapture:(id)inSender;
-(IBAction)configureMovieCapture:(id)inSender;

-(IBAction)trim:(id)inSender;
-(IBAction)setBeginning:(id)inSender;
-(IBAction)setEnd:(id)inSender;

@end
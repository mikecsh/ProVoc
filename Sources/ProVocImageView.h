//
//  ProVocImageView.h
//  ProVoc
//
//  Created by Simon Bovet on 09.04.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ProVocImageView : NSImageView {
	IBOutlet id mDelegate;
}

-(IBAction)displayFullImage:(id)inSender;

@end

@protocol ProVocImageViewDelegate

-(void)imageView:(ProVocImageView *)inImageView didReceiveDraggedImageFile:(NSString *)inFile;

@end

@interface NSScreen (FullScreen)

+(NSRect)totalFrame;

@end

@interface NSImage (ProVocImageView)

-(void)displayInFullSize;

@end

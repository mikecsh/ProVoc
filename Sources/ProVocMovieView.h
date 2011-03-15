//
//  ProVocMovieView.h
//  ProVoc
//
//  Created by Simon Bovet on 16.04.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <QTKit/QTKit.h>

@interface ProVocMovieView : QTMovieView

-(IBAction)fullScreen:(id)inSender;

@end

@interface QTMovie (ProVocMovieView)

-(NSSize)imageSize;
-(void)displayInFullSize;

@end
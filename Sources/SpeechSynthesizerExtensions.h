//
//  SpeechSynthesizerExtensions.h
//  ProVoc
//
//  Created by Simon Bovet on 19.05.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSSpeechSynthesizer (ProVoc)

+(NSSpeechSynthesizer *)commonSpeechSynthesizer;
+(void)setDefaultVoice:(NSString *)inVoice;

@end

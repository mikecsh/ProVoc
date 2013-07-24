//
//  SpeechSynthesizerExtensions.m
//  ProVoc
//
//  Created by Simon Bovet on 19.05.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "SpeechSynthesizerExtensions.h"


@implementation NSSpeechSynthesizer (ProVoc)

static NSSpeechSynthesizer *sSpeechSynthesizer = nil;
static NSString *sDefaultVoice = nil;

+(NSSpeechSynthesizer *)commonSpeechSynthesizer
{
	if (!sSpeechSynthesizer) {
		sSpeechSynthesizer = [[NSSpeechSynthesizer alloc] initWithVoice:sDefaultVoice];
		if (!sSpeechSynthesizer)
			sSpeechSynthesizer = [[NSSpeechSynthesizer alloc] initWithVoice:nil];
	}
	return sSpeechSynthesizer;
}

+(void)setDefaultVoice:(NSString *)inVoice
{
	if (![sDefaultVoice isEqual:inVoice]) {
		[sSpeechSynthesizer release];
		sSpeechSynthesizer = nil;
		[sDefaultVoice release];
		sDefaultVoice = [inVoice retain];
	}
}

@end

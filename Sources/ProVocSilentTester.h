//
//  ProVocSilentTester.h
//  ProVoc
//
//  Created by Simon Bovet on 02.11.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ProVocTester.h"

@interface ProVocSilentTester : ProVocTester {
}

-(void)setLanguageSettings:(NSDictionary *)inSettings;
-(void)setLanguage:(NSString *)inLanguage;
-(BOOL)isString:(NSString*)inString equalToString:(NSString*)inOtherString;
-(BOOL)isString:(NSString*)inString equalToSynonymOfString:(NSString*)inOtherString;
-(BOOL)isGenericString:(NSString*)inString equalToSynonymOfString:(NSString*)inOtherString;

@end

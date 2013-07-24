//
//  ScannerExtensions.h
//  ProVoc
//
//  Created by Simon Bovet on 21.04.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSScanner (ProVocExtensions)

-(BOOL)scanLineOfTabSeparatedWords:(NSArray **)outWords;
-(BOOL)scanQuotedWord:(NSString **)outWord;
-(BOOL)scanLineOfCSVWords:(NSArray **)outWords;
-(BOOL)scanCharacter:(unichar *)outChar fromSet:(NSCharacterSet *)inCharacterSet;
-(BOOL)scanHexLongLong:(long long *)outValue;

@end

@interface NSCharacterSet (ProVocExtensions)

+(NSCharacterSet *)spaceCharacterSet;
+(NSCharacterSet *)newlineCharacterSet;
+(NSCharacterSet *)tabCharacterSet;
+(NSCharacterSet *)tabAndNewlineCharacterSet;

+(NSCharacterSet *)wordSeparatorCharacterSet;
+(NSCharacterSet *)separatorCharacterSet;
+(NSCharacterSet *)emptyCharacterSet;

@end

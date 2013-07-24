//
//  StringExtensions.h
//  ProVoc
//
//  Created by Simon Bovet on 24.04.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (StringExtensions)

-(NSString *)stringByRemovingAccents;
-(NSString *)stringByDeletingWords:(NSArray *)inWords;
-(NSString *)stringByDeletingCharactersInSet:(NSCharacterSet *)inCharacterSet;

-(float)heightForWidth:(float)inWidth withAttributes:(NSDictionary *)inAttributes;
-(NSSize)sizeWithAttributes:(NSDictionary *)inAttributes;
-(float)widthWithAttributes:(NSDictionary *)inAttributes;

-(NSString *)nameOfCopyWithExistingNames:(NSArray *)inNames;

@end

@interface NSMutableString (StringExtensions)

-(void)removeAccents;
-(void)deleteWords:(NSArray *)inWords;
-(void)deleteCharactersInSet:(NSCharacterSet *)inCharacterSet;
-(void)deleteParenthesis;

@end

@interface NSAttributedString (ProVocExtensions)

-(float)heightForWidth:(float)inWidth;
-(NSSize)size;
-(float)width;

@end

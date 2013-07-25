//
//  TransformerExtensions.m
//  ProVoc
//
//  Created by Simon Bovet on 08.10.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import "TransformerExtensions.h"

@implementation PercentTransformer

+(Class)transformedValueClass
{
    return [NSNumber class];
}

+(BOOL)allowsReverseTransformation
{
    return YES;   
}

-(id)transformedValue:(id)inValue
{
	if ([inValue respondsToSelector:@selector(floatValue)])
		return @([inValue floatValue] * 100);
	else
		return nil;
}

-(id)reverseTransformedValue:(id)inValue
{
	if ([inValue respondsToSelector:@selector(floatValue)])
		return @([inValue floatValue] / 100);
	else
		return nil;
}

@end

@implementation PVSizeTransformer

+(Class)transformedValueClass
{
    return [NSString class];
}

+(BOOL)allowsReverseTransformation
{
    return YES;
}

-(float)scale
{
	switch ([[NSUserDefaults standardUserDefaults] integerForKey:PVSizeUnit]) {
		case 0:
			return 2.54 / 72;
		case 3:
			return 25.4 / 72;
		case 1:
			return 1.0 / 72;
		default:
			return 1;
	}
}

-(id)transformedValue:(id)inValue
{
	if ([inValue respondsToSelector:@selector(floatValue)]) {
		NSString *format;
		switch ([[NSUserDefaults standardUserDefaults] integerForKey:PVSizeUnit]) {
			case 2:
				format = @"%0.0f";
				break;
			case 3:
				format = @"%0.1f";
				break;
			default:
				format = @"%0.2f";
				break;
		}
		return [NSString stringWithFormat:format, [inValue floatValue] * [self scale]];
	} else
		return nil;
}

-(id)reverseTransformedValue:(id)inValue
{
	if ([inValue respondsToSelector:@selector(floatValue)])
		return @([inValue floatValue] / [self scale]);
	else
		return nil;
}

@end

@implementation PVSearchFontSizeTransformer

+(Class)transformedValueClass
{
    return [NSNumber class];
}

+(BOOL)allowsReverseTransformation
{
    return NO;
}

-(id)transformedValue:(id)inValue
{
	if ([inValue respondsToSelector:@selector(floatValue)])
		return @(MIN(13, [inValue floatValue]));
	else
		return inValue;
}

@end

@implementation PVInputFontSizeTransformer

+(Class)transformedValueClass
{
    return [NSNumber class];
}

+(BOOL)allowsReverseTransformation
{
    return NO;
}

+(float)maxSize
{
	return 72;
}

-(id)transformedValue:(id)inValue
{
	if ([inValue respondsToSelector:@selector(floatValue)])
		return @(MIN([[self class] maxSize], [inValue floatValue]));
	else
		return inValue;
}

@end

@implementation PVWritingDirectionToAlignmentTransformer

+(Class)transformedValueClass
{
    return [NSNumber class];
}

+(BOOL)allowsReverseTransformation
{
    return NO;
}

-(id)transformedValue:(id)inValue
{
	if ([inValue respondsToSelector:@selector(intValue)]) {
		int alignment = NSLeftTextAlignment;
		if ([inValue intValue] == NSWritingDirectionRightToLeft)
			alignment = NSRightTextAlignment;
		return @(alignment);
	} else
		return inValue;
}

@end

@implementation EnabledTextColorTransformer

+(Class)transformedValueClass
{
    return [NSColor class];
}

+(BOOL)allowsReverseTransformation
{
    return NO;   
}

-(id)transformedValue:(id)inValue
{
	if (![inValue respondsToSelector:@selector(boolValue)] || [inValue boolValue])
		return [NSColor controlTextColor];
	else
		return [NSColor disabledControlTextColor];
}

@end

@implementation TimerDurationTransformer

+(Class)transformedValueClass
{
    return [NSString class];
}

+(BOOL)allowsReverseTransformation
{
    return YES;
}

-(id)transformedValue:(id)inValue
{
	if ([inValue respondsToSelector:@selector(floatValue)]) {
		int seconds = [inValue floatValue];
		return [NSString stringWithFormat:@"%i:%02i", seconds / 60, seconds % 60];
	} else
		return nil;
}

-(id)reverseTransformedValue:(id)inValue
{
	int seconds = 0;
	if ([inValue respondsToSelector:@selector(rangeOfString:)]) {
		NSMutableString *string = [[inValue mutableCopy] autorelease];
		[string replaceOccurrencesOfString:@":" withString:@"" options:0 range:NSMakeRange(0, [string length])];
		seconds = [string intValue];
	} else if ([inValue respondsToSelector:@selector(intValue)])
		seconds = [inValue intValue];
	int minutes = seconds / 100;
	seconds = MIN(60, seconds % 100);
	return [NSNumber numberWithFloat:minutes * 60 + seconds];
}

@end

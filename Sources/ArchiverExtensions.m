//
//  ArchiverExtensions.m
//  ProVoc
//
//  Created by Simon Bovet on 07.05.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ArchiverExtensions.h"


@implementation PseudoKeyedArchiver

-(void)encodeBool:(BOOL)value forKey:(NSString *)key
{
    [self encodeValueOfObjCType:@encode(BOOL) at:&value];
}

-(void)encodeBytes:(const uint8_t *)bytesp length:(unsigned)lenv forKey:(NSString *)key
{
    [self encodeBytes:bytesp length:lenv];
}

-(void)encodeConditionalObject:(id)object forKey:(NSString *)key
{
    [self encodeConditionalObject:object];
}

-(void)encodeDouble:(double)value forKey:(NSString *)key
{
    [self encodeValueOfObjCType:@encode(double) at:&value];
}

-(void)encodeFloat:(float)value forKey:(NSString *)key
{
    [self encodeValueOfObjCType:@encode(float) at:&value];
}

-(void)encodeInt:(int)value forKey:(NSString *)key
{
    [self encodeValueOfObjCType:@encode(int) at:&value];
}

/*
-(void)encodeInt32:forKey:(NSString *)key


-(void)encodeInt64:forKey:(NSString *)key
*/

-(void)encodeObject:(id)object forKey:(NSString *)key
{
    [self encodeObject:object];
}

-(void)encodePoint:(NSPoint)point forKey:(NSString *)key
{
    [self encodePoint:point];
}

-(void)encodeRect:(NSRect)rect forKey:(NSString *)key
{
    [self encodeRect:rect];
}

-(void)encodeSize:(NSSize)size forKey:(NSString *)key
{
    [self encodeSize:size];
}

@end

@implementation PseudoKeyedUnarchiver

-(BOOL)decodeBoolForKey:(NSString *)key
{
    BOOL value;
    [self decodeValueOfObjCType:@encode(BOOL) at:&value];
    return value;
}

-(const uint8_t *)decodeBytesForKey:(NSString *)key returnedLength:(unsigned *)lengthp
{
    return [self decodeBytesWithReturnedLength:lengthp];
}

-(double)decodeDoubleForKey:(NSString *)key
{
    double value;
    [self decodeValueOfObjCType:@encode(double) at:&value];
    return value;
}

-(float)decodeFloatForKey:(NSString *)key
{
    float value;
    [self decodeValueOfObjCType:@encode(float) at:&value];
    return value;
}

-(int)decodeIntForKey:(NSString *)key
{
    int value;
    [self decodeValueOfObjCType:@encode(int) at:&value];
    return value;
}

/*
- decodeInt32ForKey:(NSString *)key


- decodeInt64ForKey:(NSString *)key

*/

-(id)decodeObjectForKey:(NSString *)key
{
    return [self decodeObject];
}

-(NSPoint)decodePointForKey:(NSString *)key
{
    return [self decodePoint];
}

-(NSSize)decodeSizeForKey:(NSString *)key
{
    return [self decodeSize];
}

-(NSRect)decodeRectForKey:(NSString *)key
{
    return [self decodeRect];
}

@end
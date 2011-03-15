//
//  TransformerExtensions.h
//  ProVoc
//
//  Created by Simon Bovet on 08.10.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PercentTransformer : NSValueTransformer 

@end

#define PVSizeUnit @"sizeUnit"

@interface PVSizeTransformer : NSValueTransformer 

@end

@interface PVSearchFontSizeTransformer : NSValueTransformer

@end

@interface PVInputFontSizeTransformer : NSValueTransformer

+(float)maxSize;

@end

@interface PVWritingDirectionToAlignmentTransformer : NSValueTransformer

@end

@interface EnabledTextColorTransformer : NSValueTransformer 

@end

@interface TimerDurationTransformer : NSValueTransformer

@end

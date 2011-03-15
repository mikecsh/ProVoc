#import <Cocoa/Cocoa.h>

@interface RankCell : NSCell {
}

-(float)floatValue;
-(void)setFloatValue:(float)inValue;

@end

@interface PresetCell : NSCell {
	id mDelegate;
}

-(void)setDelegate:(id)inDelegate;

@end

@interface ImageAndTextCell : NSTextFieldCell {
@private
    NSImage	*image;
}

- (void)setImage:(NSImage *)anImage;
- (NSImage *)image;

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (NSSize)cellSize;

@end

@interface FlaggedTextCell : NSTextFieldCell {
@private
    NSImage	*image;
}

- (void)setImage:(NSImage *)anImage;
- (NSImage *)image;

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (NSSize)cellSize;

@end

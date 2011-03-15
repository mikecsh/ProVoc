#import "ExtendedCell.h"
#import "ProVocPreset.h"
#import "StringExtensions.h"
#import "ProVocDocument+Lists.h"
#import "TransformerExtensions.h"

static NSImage *sRankPatternImage = nil;

@implementation RankCell

+ (void) initialize
{
	sRankPatternImage = [[NSImage imageNamed:@"stripe"] retain];
	// This should be a 2-pixel by 1-pixel image with the following colors:
	// For dark stripe:  r = g = b = 0, a = 136/255 = 0.533
	// For light stripe: r = g = b = 0, a = 183/255 = 0.718
	// (I didn't really get this value right, if somebody has a correct image,
	// feel free to send it to me...)
}

- (float) floatValue
{
	float result = 0.0;
	id objectValue = [self objectValue];
	if ([objectValue respondsToSelector:@selector(floatValue)])
	{
		result = [(NSNumber *)objectValue floatValue];
	}
	return result;
}

- (void) setFloatValue:(float)inValue
{
	float value = inValue;
	if (value > 1.0) value = 1.0;
	if (value < 0.0) value = 0.0;
	[self setObjectValue:[NSNumber numberWithFloat:value]];
}

/*"	Draw the cell's contents.
"*/
- (void) drawInteriorWithFrame: (NSRect)inFrame inView: (NSView*)inView;
{
	float drawWidth;
	NSRect fillFrame, eraseFrame;

	// Constrain the frame's height
	float yInset = (NSSmallControlSize == [self controlSize]) ? 4.0 : 3.0;
	NSRect newFrame = NSInsetRect(inFrame, 3.0, yInset);

	// Calculate width of filled part
	drawWidth = floor([self floatValue] * newFrame.size.width);
	if (drawWidth < 1)
	{
		drawWidth = 1;	//  at least 1 pixel wide, so we see something!
	}

	NSDivideRect(newFrame, &fillFrame, &eraseFrame, drawWidth, NSMinXEdge);
	const float maxHeight = 13;
	if (fillFrame.size.height > maxHeight) {
		fillFrame.origin.y = NSMidY(fillFrame) - maxHeight / 2;
		fillFrame.size.height = maxHeight;
	}

	[[NSColor colorWithPatternImage:sRankPatternImage] set];
	[NSBezierPath fillRect:fillFrame];
}



@end


@implementation PresetCell

-(void)setDelegate:(id)inDelegate
{
	mDelegate = inDelegate;
}

-(void)drawInteriorWithFrame:(NSRect)inFrame inView:(NSView *)inView
{
	static NSDictionary *titleAttributes = nil;
	static NSDictionary *messageAttributes = nil;
	if (!titleAttributes) {
		titleAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont boldSystemFontOfSize:0], NSFontAttributeName, nil];
		messageAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName, nil];
	}
	NSRect iconFrame;
	NSRect titleFrame;
	NSRect messageFrame;
	NSRect onlyFrame;
	NSDivideRect(NSInsetRect(inFrame, 4, 4), &iconFrame, &titleFrame, 65, NSMinXEdge);
	NSDivideRect(titleFrame, &titleFrame, &messageFrame, 17, NSMinYEdge);
	NSDivideRect(messageFrame, &onlyFrame, &messageFrame, 17, NSMaxYEdge);
	
	ProVocPreset *preset = [self objectValue];
	NSDictionary *parameters = [preset parameters];

	NSPoint origin = NSMakePoint(NSMinX(iconFrame), NSMidY(iconFrame) + 24);
	NSImage *image;
	NSString *icon;
	
	int direction = [[parameters objectForKey:@"testDirection"] intValue];
	switch (direction) {
		case 0:		icon = @"Version"; break;
		case 1: 	icon = @"Theme"; break;
		case 3: 	icon = @"Both"; break;
		default:	icon = @""; break;
	}
	if ([icon length] > 0) {
		image = [NSImage imageNamed:icon];
		[image dissolveToPoint:origin fraction:1.0];
	}
	
	NSMutableString *message = [NSMutableString string];
	[[NSImage imageNamed:@"Question"] dissolveToPoint:origin fraction:1.0];
	if ([[parameters objectForKey:@"testMCQ"] boolValue]) {
		[[NSImage imageNamed:@"MCQ"] dissolveToPoint:origin fraction:1.0];
		int choices = [[parameters objectForKey:@"testMCQNumber"] intValue];
		if ([[parameters objectForKey:@"imageMCQ"] boolValue]) {
			if ([[parameters objectForKey:@"delayedMCQ"] boolValue])
				[message appendFormat:NSLocalizedString(@"%i delayed choices with images. ", @""), choices];
			else
				[message appendFormat:NSLocalizedString(@"%i choices with images. ", @""), choices];
		} else {
			if ([[parameters objectForKey:@"delayedMCQ"] boolValue])
				[message appendFormat:NSLocalizedString(@"%i delayed choices. ", @""), choices];
			else
				[message appendFormat:NSLocalizedString(@"%i choices. ", @""), choices];
		}
	}

	switch ([[parameters objectForKey:@"testKind"] intValue]) {
		case 0:
			[message appendString:NSLocalizedString(@"Normal mode. ", @"")];
			break;
		case 1:
			[message appendString:NSLocalizedString(@"Continuous mode. ", @"")];
			[[NSImage imageNamed:@"Continuous"] dissolveToPoint:origin fraction:1.0];
			break;
		case 2:
			[message appendString:NSLocalizedString(@"Until learned. ", @"")];
			break;
	}

	int attempts = [[parameters objectForKey:@"numberOfRetries"] intValue];
	if (attempts > 1)
		[message appendFormat:NSLocalizedString(@"%i attempts. ", @""), attempts];
	else
		[message appendFormat:NSLocalizedString(@"%i attempt. ", @""), attempts];

	switch ([[parameters objectForKey:@"lateComments"] intValue]) {
		case 0:
			[message appendString:NSLocalizedString(@"Comments displayed with question. ", @"")];
			break;
		case 1:
			[message appendString:NSLocalizedString(@"Comments displayed after answer. ", @"")];
			break;
		case 2:
			[message appendString:NSLocalizedString(@"Comments not displayed. ", @"")];
			break;
		case 3:
			[message appendFormat:NSLocalizedString(@"Comments displayed with %@. ", @""), [mDelegate sourceLanguage]];
			break;
		case 4:
			[message appendFormat:NSLocalizedString(@"Comments displayed with %@. ", @""), [mDelegate targetLanguage]];
			break;
	}
	
	if ([[parameters objectForKey:@"timer"] intValue] == 2) {
		TimerDurationTransformer *transformer = [[[TimerDurationTransformer alloc] init] autorelease];
		[message appendFormat:NSLocalizedString(@"Timer duration: %@. ", @""), [transformer transformedValue:[parameters objectForKey:@"timerDuration"]]];
	}
			
	NSString *name = [preset name];
	[name drawInRect:titleFrame withAttributes:titleAttributes];
	messageFrame.size.height = 28;
	[message drawInRect:messageFrame withAttributes:messageAttributes];
	
	BOOL reviewOnly = [[parameters objectForKey:@"testWordsToReview"] boolValue];
	BOOL markedOnly = [[parameters objectForKey:@"testMarked"] boolValue];
	BOOL oldOnly = [[parameters objectForKey:@"testOldWords"] boolValue];
	BOOL limitOnly = [[parameters objectForKey:@"testLimit"] boolValue];
	if (reviewOnly || markedOnly | oldOnly | limitOnly) {
		NSString *message = NSLocalizedString(@"Test only:", @"");
		[message drawInRect:onlyFrame withAttributes:messageAttributes];

		NSPoint origin = onlyFrame.origin;
		origin.x += 4 + [message widthWithAttributes:messageAttributes];
		if (markedOnly) {
			NSIndexSet *labelsToTest = [parameters objectForKey:@"labelsToTest"];		
			origin.y = NSMaxY(onlyFrame) - 3;
			int label;
			for (label = 0; label <= 9; label++)
				if ([labelsToTest containsIndex:label]) {
					NSImage *image = label == 0 ? [NSImage imageNamed:@"flagged"] : [ProVocDocument imageForLabel:label - 1];
					[image dissolveToPoint:origin fraction:fraction];
					origin.x += [image size].width;
				}
			origin.x += 4;
		}
		
		if (reviewOnly | oldOnly | limitOnly) {
			NSString *limitMessage = nil;
			NSString *subMessage;

			if (reviewOnly) {
				subMessage = NSLocalizedString(@"only words needed to be reviewed", @"");
				if (!limitMessage)
					limitMessage = subMessage;
				else
					limitMessage = [NSString stringWithFormat:NSLocalizedString(@"Limit Both %@ and %@", @""), limitMessage, subMessage];
			}

			if (limitOnly) {
				int number = [[parameters objectForKey:@"testLimitNumber"] intValue];
				switch ([[parameters objectForKey:@"testLimitWhat"] intValue]) {
					case 0:
						subMessage = NSLocalizedString(@"%i random words", @"");
						break;
					case 1:
						subMessage = NSLocalizedString(@"%i most difficult words", @"");
						break;
				}
				subMessage = [NSString stringWithFormat:subMessage, number];
				if (!limitMessage)
					limitMessage = subMessage;
				else
					limitMessage = [NSString stringWithFormat:NSLocalizedString(@"Limit Both %@ and %@", @""), limitMessage, subMessage];
			}

			if (oldOnly) {
				int number = [[parameters objectForKey:@"testOldNumber"] intValue];
				switch ([[parameters objectForKey:@"testOldUnit"] intValue]) {
					case 0:
						if (number > 1)
							subMessage = NSLocalizedString(@"%i Days", @"");
						else
							subMessage = NSLocalizedString(@"%i Day", @"");
						break;
					case 1:
						if (number > 1)
							subMessage = NSLocalizedString(@"%i Weeks", @"");
						else
							subMessage = NSLocalizedString(@"%i Week", @"");
						break;
					case 2:
						if (number > 1)
							subMessage = NSLocalizedString(@"%i Months", @"");
						else
							subMessage = NSLocalizedString(@"%i Month", @"");
						break;
				}
				subMessage = [NSString stringWithFormat:subMessage, number];
				subMessage = [NSString stringWithFormat:NSLocalizedString(@"Older Than %@ Format", @""), subMessage];
				if (!limitMessage)
					limitMessage = subMessage;
				else
					limitMessage = [NSString stringWithFormat:NSLocalizedString(@"Limit Both %@ and %@", @""), limitMessage, subMessage];
			}
			
			NSRect frame = onlyFrame;
			frame.origin.x = origin.x;
			frame.size.width = NSMaxX(onlyFrame) - frame.origin.x;
			[limitMessage drawInRect:frame withAttributes:messageAttributes];
		}
	}
}



@end

@implementation ImageAndTextCell

- (void)dealloc {
    [image release];
    image = nil;
    [super dealloc];
}

- copyWithZone:(NSZone *)zone {
    ImageAndTextCell *cell = (ImageAndTextCell *)[super copyWithZone:zone];
    cell->image = [image retain];
    return cell;
}

- (void)setImage:(NSImage *)anImage {
    if (anImage != image) {
        [image release];
        image = [anImage retain];
    }
}

- (NSImage *)image {
    return image;
}

#define MARGIN 4

- (NSRect)imageFrameForCellFrame:(NSRect)cellFrame {
    if (image != nil) {
        NSRect imageFrame;
        imageFrame.size = [image size];
        imageFrame.origin = cellFrame.origin;
        imageFrame.origin.x += MARGIN;
        imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
        return imageFrame;
    }
    else
        return NSZeroRect;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
    NSRect textFrame, imageFrame;
    NSDivideRect (aRect, &imageFrame, &textFrame, MARGIN + [image size].width, NSMinXEdge);
    [super editWithFrame: textFrame inView: controlView editor:textObj delegate:anObject event: theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength {
    NSRect textFrame, imageFrame;
    NSDivideRect (aRect, &imageFrame, &textFrame, MARGIN + [image size].width, NSMinXEdge);
    [super selectWithFrame: textFrame inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    if (image != nil) {
        NSSize	imageSize;
        NSRect	imageFrame;

        imageSize = [image size];
        NSDivideRect(cellFrame, &imageFrame, &cellFrame, MARGIN + imageSize.width, NSMinXEdge);
        if ([self drawsBackground]) {
            [[self backgroundColor] set];
            NSRectFill(imageFrame);
        }
        imageFrame.origin.x += MARGIN / 2;
        imageFrame.size = imageSize;

        if ([controlView isFlipped])
            imageFrame.origin.y += floor((cellFrame.size.height + imageFrame.size.height) / 2);
        else
            imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);

        [image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
    }
	if ([NSApp systemVersion] >= 0x1040)
		[self setLineBreakMode:NSLineBreakByTruncatingTail];
    [super drawWithFrame:cellFrame inView:controlView];
}

- (NSSize)cellSize {
    NSSize cellSize = [super cellSize];
    cellSize.width += (image ? [image size].width : 0) + MARGIN;
    return cellSize;
}

@end

@implementation FlaggedTextCell

- (void)dealloc {
    [image release];
    image = nil;
    [super dealloc];
}

- copyWithZone:(NSZone *)zone {
    FlaggedTextCell *cell = (FlaggedTextCell *)[super copyWithZone:zone];
    cell->image = [image retain];
    return cell;
}

- (void)setImage:(NSImage *)anImage {
    if (anImage != image) {
        [image release];
        image = [anImage retain];
    }
}

- (NSImage *)image {
    return image;
}

-(NSRect)textFrameForCellFrame:(NSRect)inCellFrame
{
	if (image) {
		float dx = [image size].width + MARGIN;
		inCellFrame.origin.x += dx;
		inCellFrame.size.width -= dx;
	}
	return inCellFrame;
}

- (NSRect)imageFrameForCellFrame:(NSRect)cellFrame {
    if (image != nil) {
        NSRect imageFrame;
        imageFrame.size = [image size];
        imageFrame.origin = cellFrame.origin;
//        imageFrame.origin.x += cellFrame.size.width - imageFrame.size.width - MARGIN;
        imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
        return imageFrame;
    }
    else
        return NSZeroRect;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{
    [super editWithFrame:[self textFrameForCellFrame:aRect] inView: controlView editor:textObj delegate:anObject event: theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength
{
    [super selectWithFrame:[self textFrameForCellFrame:aRect] inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    if (image != nil) {
        NSSize	imageSize;
        NSRect	imageFrame;

        imageSize = [image size];
        NSDivideRect(cellFrame, &imageFrame, &cellFrame, image ? MARGIN + imageSize.width : 0, NSMinXEdge);
        if ([self drawsBackground]) {
            [[self backgroundColor] set];
            NSRectFill(imageFrame);
        }
        imageFrame.origin.x += MARGIN / 2;
        imageFrame.size = imageSize;

        if ([controlView isFlipped])
            imageFrame.origin.y += floor((cellFrame.size.height + imageFrame.size.height) / 2);
        else
            imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);

        [image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
    }
	if ([NSApp systemVersion] >= 0x1040)
		[self setLineBreakMode:NSLineBreakByTruncatingTail];
    [super drawWithFrame:cellFrame inView:controlView];
}

- (NSSize)cellSize {
    NSSize cellSize = [super cellSize];
    cellSize.width += (image ? [image size].width : 0) + MARGIN;
    return cellSize;
}

@end


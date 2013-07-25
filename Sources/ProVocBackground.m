//
//  ProVocBackground.m
//  ProVoc
//
//  Created by Simon Bovet on 23.04.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ProVocBackground.h"
#import "ProVocApplication.h"
#import "ProVocTester.h"

@implementation ProVocBackground

+(BOOL)isAvailable
{
	return [NSApp systemVersion] >= 0x1040;
}

+(ProVocBackground *)sharedBackground
{
	if (![self isAvailable])
		return nil;
	static ProVocBackground *sharedBackground = nil;
	if (!sharedBackground)
		sharedBackground = [[ProVocBackground alloc] initWithWindowNibName:@"ProVocBackground"];
	return sharedBackground;
}

-(id)initWithWindowNibName:(NSString *)inName
{
	if (self = [super initWithWindowNibName:inName]) {
		[self loadWindow];
		mInputsToTrigger = [[NSMutableArray alloc] initWithCapacity:0];
		mWindow = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 200, 200) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
		[mWindow setContentView:mView];
		[mWindow setLevel:NSFloatingWindowLevel + 1];
		[mWindow setHasShadow:NO];
		[mView stopRendering];
		NSString *path = [ProVocBackgroundStyle customBackgroundCompositionPath];
		if (path)
			[self setCompositionPath:path];
		else
			[self setStyle:[ProVocBackgroundStyle currentBackgroundStyle]];
	}
	return self;
}

-(void)setStyle:(ProVocBackgroundStyle *)inStyle
{
	[self setCompositionPath:[inStyle compositionPath]];
}

-(void)setCompositionPath:(NSString *)inPath
{
	[mView loadCompositionFromFile:inPath];
}

-(void)display
{
	if (![[NSUserDefaults standardUserDefaults] boolForKey:PVEnableBackground])
		return;
	NSEnumerator *enumerator = [[mView inputKeys] objectEnumerator];
	NSString *key;
	while (key = [enumerator nextObject])
		if ([key hasPrefix:@"Previous"])
			[mView setValue:nil forInputKey:key];
	NSColor *color = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:PVTestBackgroundColor]];
	[self setValue:color forInputKey:@"Color"];
	[self setValue:@(((float)(rand() % 30000)) / 30000) forInputKey:@"Random"];
	[mView startRendering];
	NSSize maxSize = NSMakeSize(2000, 2000);
	NSRect frame = [[NSScreen mainScreen] frame];
	frame = NSInsetRect(frame, MAX(0, (frame.size.width - maxSize.width) / 2), MAX(0, (frame.size.height - maxSize.height) / 2));
	frame.origin.x = round(frame.origin.x);
	frame.origin.y = round(frame.origin.y);
	[mWindow setFrame:frame display:NO];
	[mWindow orderFront:nil];
	if ([mInputsToTrigger count] > 0) {
		[self triggerInputKeys:mInputsToTrigger];
		[mInputsToTrigger removeAllObjects];
	}
	[self triggerInputKey:@"Reset"];
	[self triggerInputKey:@"Start"];
	mDisplayed = YES;
}

-(void)hide
{
	if (mDisplayed) {
		[mWindow orderOut:nil];
		[mView stopRendering];
		mDisplayed = NO;
	}
}

-(void)displayNow
{
	if (mDisplayed)
		[mView display];
}

-(void)setValue:(id)inValue forInputKey:(NSString *)inKey
{
	if ([[mView inputKeys] containsObject:inKey]) {
		NSString *previousKey = [@"Previous" stringByAppendingString:inKey];
		if ([[mView inputKeys] containsObject:previousKey])
			[mView setValue:[mView valueForInputKey:inKey] forInputKey:previousKey];
		[mView setValue:inValue forInputKey:inKey];
		NSString *triggerKey = [@"Change" stringByAppendingString:inKey];
		if ([[mView inputKeys] containsObject:triggerKey])
			[self triggerInputKey:triggerKey];
	}
}

-(void)setValue:(id)inValue forInputKeys:(NSArray *)inKeys
{
	NSEnumerator *enumerator = [inKeys objectEnumerator];
	NSString *key;
	while (key = [enumerator nextObject])
		if ([[mView inputKeys] containsObject:key])
			[mView setValue:inValue forInputKey:key];
}

-(void)triggerInputKeys:(NSArray *)inKeys
{
	if ([mView isRendering]) {
		[self setValue:@YES forInputKeys:inKeys];
		[mView display];
		[self setValue:@NO forInputKeys:inKeys];
	} else
		[mInputsToTrigger addObjectsFromArray:inKeys];
}

-(void)triggerInputKey:(NSString *)inKey
{
	[self triggerInputKeys:@[inKey]];
}

@end

@implementation ProVocBackgroundStyle

+(NSMutableArray *)allBackgroundCompositionPaths
{
    NSArray *librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES);
    NSEnumerator *searchPathEnum = [librarySearchPaths objectEnumerator];
    NSString *currPath;
    NSMutableArray *bundleSearchPaths = [NSMutableArray array];
    NSMutableArray *allBundles = [NSMutableArray array];
    
    while (currPath = [searchPathEnum nextObject])
        [bundleSearchPaths addObject:[currPath stringByAppendingPathComponent:@"Application Support/ProVoc/Backgrounds"]];
    
    searchPathEnum = [bundleSearchPaths objectEnumerator];
    while (currPath = [searchPathEnum nextObject]) {
        NSDirectoryEnumerator *bundleEnum;
        NSString *currBundlePath;
        if (bundleEnum = [[NSFileManager defaultManager] enumeratorAtPath:currPath])
            while (currBundlePath = [bundleEnum nextObject])
                if ([[currBundlePath pathExtension] isEqualToString:@"qtz"] && [currBundlePath rangeOfString:@".pvback/"].location == NSNotFound)
					[allBundles addObject:[currPath stringByAppendingPathComponent:currBundlePath]];
    }
    
    return allBundles;
}

+(NSMutableArray *)allBackgroundPaths
{
    NSArray *librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES);
    NSEnumerator *searchPathEnum = [librarySearchPaths objectEnumerator];
    NSString *currPath;
    NSMutableArray *bundleSearchPaths = [NSMutableArray array];
    NSMutableArray *allBundles = [NSMutableArray array];
    
    while (currPath = [searchPathEnum nextObject]) {
        [bundleSearchPaths addObject:[currPath stringByAppendingPathComponent:@"Application Support/ProVoc/PlugIns"]];
        [bundleSearchPaths addObject:[currPath stringByAppendingPathComponent:@"Application Support/ProVoc/Backgrounds"]];
	}
    [bundleSearchPaths addObject:[[NSBundle mainBundle] builtInPlugInsPath]];
    
    searchPathEnum = [bundleSearchPaths objectEnumerator];
    while (currPath = [searchPathEnum nextObject]) {
        NSDirectoryEnumerator *bundleEnum;
        NSString *currBundlePath;
        if (bundleEnum = [[NSFileManager defaultManager] enumeratorAtPath:currPath])
            while (currBundlePath = [bundleEnum nextObject])
                if ([[currBundlePath pathExtension] isEqualToString:@"pvback"])
					[allBundles addObject:[currPath stringByAppendingPathComponent:currBundlePath]];
    }
    
    return allBundles;
}

+(NSArray *)availableBackgroundStyles
{
	static NSArray *backgroundStyles = nil;
	if (!backgroundStyles) {
		NSMutableArray *array = [NSMutableArray array];
		NSEnumerator *enumerator = [[self allBackgroundPaths] objectEnumerator];
		NSString *path;
		while (path = [enumerator nextObject])
			[array addObject:[self backgroundStyleWithPath:path]];
		enumerator = [[self allBackgroundCompositionPaths] objectEnumerator];
		while (path = [enumerator nextObject])
			[array addObject:[self backgroundStyleWithCompositionAtPath:path]];
		[array sortUsingSelector:@selector(compareUsingName:)];
		backgroundStyles = [array copy];
	}
	return backgroundStyles;
}

+(NSArray *)availableBackgroundStyleNames
{
	NSMutableArray *names = [NSMutableArray array];
	NSEnumerator *enumerator = [[self availableBackgroundStyles] objectEnumerator];
	ProVocBackgroundStyle *style;
	while (style = [enumerator nextObject])
		[names addObject:[style name]];
	return names;
}

#define PVCurrentBackgroundCompositionPath @"currentBackgroundCompositionPath"

+(NSString *)customBackgroundCompositionPath
{
	NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:PVCurrentBackgroundCompositionPath];
	if (!path)
		return nil;
	BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
	if (!fileExists)
		return nil;
	return path;
}

+(void)setCustomBackgroundCompositionPath:(NSString *)inPath
{
	[[NSUserDefaults standardUserDefaults] setObject:inPath forKey:PVCurrentBackgroundCompositionPath];
	NSString *path = [self customBackgroundCompositionPath];
	if (path)
		[[ProVocBackground sharedBackground] setCompositionPath:path];
}

+(int)indexOfCurrentBackgroundStyle
{
	return [[self availableBackgroundStyles] indexOfObjectIdenticalTo:[self currentBackgroundStyle]];
}

+(void)setIndexOfCurrentBackgroundStyle:(int)inIndex
{
	[self setCurrentBackgroundStyle:[self availableBackgroundStyles][inIndex]];
}

#define PVCurrentBackgroundIdentifier @"currentBackgroundIdentifier"

-(BOOL)isDefault
{
	return [[mBundle objectForInfoDictionaryKey:@"Default"] boolValue];
}

+(ProVocBackgroundStyle *)currentBackgroundStyle
{
	ProVocBackgroundStyle *style = nil;
	NSString *identifier = [[NSUserDefaults standardUserDefaults] objectForKey:PVCurrentBackgroundIdentifier];
	if (identifier) {
		NSEnumerator *enumerator = [[self availableBackgroundStyles] objectEnumerator];
		while (style = [enumerator nextObject])
			if ([identifier isEqual:[style identifier]])
				break;
	}
	if (!style) {
		NSEnumerator *enumerator = [[self availableBackgroundStyles] objectEnumerator];
		while (style = [enumerator nextObject])
			if ([style isDefault])
				break;
	}
	if (!style)
		style = [self availableBackgroundStyles][0];
	return style;
}

+(void)setCurrentBackgroundStyle:(ProVocBackgroundStyle *)inStyle
{
	if (inStyle != [self currentBackgroundStyle]) {
		[[NSUserDefaults standardUserDefaults] setObject:[inStyle identifier] forKey:PVCurrentBackgroundIdentifier];
		[[ProVocBackground sharedBackground] setStyle:inStyle];
	}
}

+(id)backgroundStyleWithPath:(NSString *)inPath
{
	return [[[self alloc] initWithPath:inPath] autorelease];
}

-(id)initWithPath:(NSString *)inPath
{
	if (self = [super init]) {
		mBundle = [[NSBundle alloc] initWithPath:inPath];
	}
	return self;
}

+(id)backgroundStyleWithCompositionAtPath:(NSString *)inPath
{
	return [[[self alloc] initWithCompositionAtPath:inPath] autorelease];
}

-(id)initWithCompositionAtPath:(NSString *)inPath
{
	if (self = [super init]) {
		mCompositionPath = [inPath retain];
	}
	return self;
}

-(void)dealloc
{
	[mBundle release];
	[mCompositionPath release];
	[super dealloc];
}

-(id)identifier
{
	if (mBundle)
		return [mBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
	else
		return [mCompositionPath lastPathComponent];
}

-(NSString *)compositionPath
{
	if (mBundle)
		return [[mBundle bundlePath] stringByAppendingPathComponent:[mBundle objectForInfoDictionaryKey:@"QuartzComposition"]];
	else
		return mCompositionPath;
}

-(NSString *)name
{
	if (mBundle)
		return [mBundle objectForInfoDictionaryKey:@"CFBundleName"];
	else
		return [[mCompositionPath lastPathComponent] stringByDeletingPathExtension];
}

-(NSComparisonResult)compareUsingName:(ProVocBackgroundStyle *)inComposer
{
	return [[self name] compare:[inComposer name]];
}

@end

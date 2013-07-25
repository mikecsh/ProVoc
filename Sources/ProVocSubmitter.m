//
//  ProVocSubmitter.m
//  FTPTest
//
//  Created by Simon Bovet on 08.05.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import "ProVocSubmitter.h"

#import <AddressBook/AddressBook.h>


@implementation ProVocSubmitter

+(void)initialize
{
	[self setKeys:[NSArray arrayWithObjects:@"title", nil] triggerChangeNotificationsForDependentKey:@"canSubmit"];
}

-(id)init
{
	if (self = [super initWithWindowNibName:@"ProVocSubmitter"]) {
		[self loadWindow];
	}
	return self;
}

-(void)dealloc
{
	[mFile release];
	[mCompresser release];
	[mUploader release];
	[mTitle release];
	[mAuthor release];
	[mComments release];
	[progressLabel release];
	[mSubmissionIdentifier release];
	[mConfirmationString release];
	[mDestination release];
	[mInfo release];
	[super dealloc];
}

-(void)setDelegate:(id)inDelegate
{
	mDelegate = inDelegate;
}

-(void)submitFile:(NSString *)inFile
	sourceLanguage:(NSString *)inSourceLanguage
	targetLanguage:(NSString *)inTargetLanguage
	info:(NSDictionary *)inInfo
	modalForWindow:(NSWindow *)inWindow
{
	mInfo = [[NSMutableDictionary dictionary] retain];
	[mInfo setObject:inSourceLanguage forKey:@"Source"];
	[mInfo setObject:inTargetLanguage forKey:@"Target"];
	if (inInfo)
		[mInfo addEntriesFromDictionary:inInfo];
	mFile = [inFile retain];

	NSDictionary *submissionInfo = [inInfo objectForKey:@"Submission Info"];
	NSString *title = [submissionInfo objectForKey:@"Title"];
	if ([title length] == 0)
		title = [[inFile lastPathComponent] stringByDeletingPathExtension];
	[self setValue:title forKey:@"title"];
	NSString *author = [submissionInfo objectForKey:@"Author"];
	if ([author length] == 0) {
		ABPerson *me = [[ABAddressBook sharedAddressBook] me];
		NSString *firstName = [me valueForProperty:kABFirstNameProperty];
		NSString *lastName = [me valueForProperty:kABLastNameProperty];
		if (!firstName) {
			if (!lastName)
				author = @"?";
			else
				author = lastName;
		} else if (!lastName)
			author = firstName;
		else
			author = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
	}
	[self setValue:author forKey:@"author"];
	NSString *comments = [submissionInfo objectForKey:@"Comments"];
	if (!comments)
		comments = @"";
	[self setValue:comments forKey:@"comments"];

	[self selectTabViewItemAtIndex:0];
	[NSApp beginSheet:[self window] modalForWindow:inWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
	[self retain];
}

-(void)sheetDidEnd:(NSWindow *)inWindow returnCode:(int)inReturnCode contextInfo:(void *)inInfo
{
	[inWindow orderOut:nil];
	if (mDestination)
		[[NSFileManager defaultManager] removeFileAtPath:mDestination handler:nil];
	[self autorelease];
}

-(BOOL)canSubmit
{
	return [mTitle length] > 0;
}

-(NSString *)title
{
	return mTitle ? mTitle : @"";
}

-(void)setTitle:(NSString *)inTitle
{
	if (mTitle != inTitle) {
		[mTitle release];
		mTitle = [inTitle retain];
	}
}

-(NSString *)author
{
	return mAuthor ? mAuthor : @"";
}

-(void)setAuthor:(NSString *)inAuthor
{
	if (mAuthor != inAuthor) {
		[mAuthor release];
		mAuthor = [inAuthor retain];
	}
}

-(NSString *)comments
{
	return mComments ? mComments : @"";
}

-(void)setComments:(NSString *)inComments
{
	if (mComments != inComments) {
		[mComments release];
		mComments = [inComments retain];
	}
}

@end

@implementation NSObject (ProVocSubmitterDelegate)

-(void)submitter:(ProVocSubmitter *)inSubmitter updateSubmissionInfo:(NSDictionary *)inInfo
{
}

@end

@implementation ProVocSubmitter (Interface)

-(void)selectTabViewItemAtIndex:(int)inIndex
{
	[mTabView setHidden:YES];
	[mTabView selectTabViewItemAtIndex:inIndex];
	float minY = 1e6;
	float maxY = 0;
	NSEnumerator *enumerator = [[[[mTabView tabViewItemAtIndex:inIndex] view] subviews] objectEnumerator];
	NSView *subview;
	while (subview = [enumerator nextObject]) {
		NSRect frame = [subview frame];
		minY = MIN(minY, NSMinY(frame));
		maxY = MAX(maxY, NSMaxY(frame));
	}
	NSWindow *window = [self window];
	NSRect frame = [window frame];
	float dy = (maxY - minY + 35) - [[window contentView] frame].size.height;
	if ([NSApp systemVersion] >= 0x1040)
		dy *= [window userSpaceScaleFactor];
	frame.size.height += dy;
	frame.origin.y -= dy;
	[window setFrame:frame display:YES animate:[window isVisible]];
	[mTabView setHidden:NO];
}

-(NSString *)submissionIdentifier
{
	if (!mSubmissionIdentifier) {
		NSString *userName = [[@"~" stringByExpandingTildeInPath] lastPathComponent];
		int timeStamp = (int)[NSDate timeIntervalSinceReferenceDate];
		mSubmissionIdentifier = [[NSString alloc] initWithFormat:@"ProVoc_%@%X", userName, timeStamp];
	}
	return mSubmissionIdentifier;
}

-(NSString *)compressedDestination
{
	if (!mDestination)
		mDestination = [[NSString alloc] initWithFormat:@"/tmp/%@.zip", [self submissionIdentifier]];
	return mDestination;
}

-(NSString *)confirmationString
{
	if (!mConfirmationString) {
		NSString *date = [[NSDate date] descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:nil locale:nil];
		NSMutableString *confirmation = [NSMutableString stringWithFormat:
				@"User:pvpublic\nIdentifier:%@\nTitle:%@\nAuthor:%@\nDate:%@\nComments:%@\n", [self submissionIdentifier], [self title], [self author], date, [self comments]];
		NSEnumerator *enumerator = [mInfo keyEnumerator];
		NSString *key;
		while (key = [enumerator nextObject])
			[confirmation appendFormat:@"%@:%@\n", key, [mInfo objectForKey:key]];
		mConfirmationString = [confirmation copy];
	}
	return mConfirmationString;
}

-(void)error:(NSString *)inMessage
{
	if (!mAborting)
		NSRunAlertPanel(NSLocalizedString(@"Submission Error Title", @""),
					[NSString stringWithFormat:NSLocalizedString(@"Submission Error Message (%@)", @""), inMessage],
					nil, nil, nil);
	[NSApp endSheet:[self window] returnCode:NSCancelButton];
}

-(BOOL)checkInternetConnection
{
	NSString *acknowledge = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://www.arizona-software.ch/~provoc/submission/check.php?action=check"] encoding:NSUTF8StringEncoding error:nil];
	return [acknowledge isEqual:@"OK"];
}

-(IBAction)submit:(id)inSender
{
	if (![self checkInternetConnection]) {
		NSRunAlertPanel(NSLocalizedString(@"Submission Connection Error Title", @""),
					NSLocalizedString(@"Submission Connection Error Message", @""),
					nil, nil, nil);
		return;
	}
	
	[self setValue:NSLocalizedString(@"Compressing", @"") forKey:@"progressLabel"];
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"indeterminateProgress"];
	[self selectTabViewItemAtIndex:1];
	[[self window] display];

	NSString *author = [self author];
	NSArray *components = [author componentsSeparatedByString:@"/"];
	if ([components count] > 1)
		author = [components objectAtIndex:0];
	NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:[self title], @"Title", author, @"Author", [self comments], @"Comments", nil];
	[mDelegate submitter:self updateSubmissionInfo:info];

	NSString *destination = [self compressedDestination];
	[[NSFileManager defaultManager] removeFileAtPath:destination handler:nil];
	mCompresser = [[ZIPCompresser alloc] initWithFile:mFile destination:destination];
	if (!mCompresser) {
		[self error:@"Could not compress file"];
		return;
	}
	[mCompresser setDelegate:self];
	[mCompresser startCompress];
}

-(void)compresser:(ZIPCompresser *)inCompresser didFinishWithCode:(int)inCode
{
	[mCompresser release];
	mCompresser = nil;
	if (inCode != 0 || mAborting) {
		[self error:@"Error while compressing file"];
		return;
	}

	NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:[self compressedDestination] traverseLink:YES];
	NSNumber *fileSize = [fileAttributes objectForKey:NSFileSize];
	if (fileSize)
		[mInfo setObject:fileSize forKey:@"FileSize"];

	[self setValue:[NSNumber numberWithFloat:0.0] forKey:@"progress"];
	[self setValue:[NSNumber numberWithBool:NO] forKey:@"indeterminateProgress"];
	[self setValue:NSLocalizedString(@"Uploading", @"") forKey:@"progressLabel"];
	mUploader = [[FTPUploader alloc] initWithUser:@"pvpublic" password:@"ZwaSb0uuB565" host:@"www.arizona-software.ch" path:@"/web/vocabulary" file:[self compressedDestination]];
	if (!mUploader) {
		[self error:@"Could not upload file"];
		return;
	}
	[mUploader setDelegate:self];
	[mUploader startUpload];
}

-(void)uploader:(FTPUploader *)inUploader progress:(float)inProgress
{
	[self setValue:[NSNumber numberWithFloat:inProgress] forKey:@"progress"];
}

-(void)uploader:(FTPUploader *)inUploader didFinishWithCode:(int)inCode
{
	[mUploader release];
	mUploader = nil;
	if (inCode != 0 || mAborting) {
		[self error:@"Error while uploading file"];
		return;
	}

	NSURL *url = [NSURL URLWithString:@"http://www.arizona-software.ch/~provoc/submission/submit.php"];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[[self confirmationString] dataUsingEncoding:NSUTF8StringEncoding]];

	NSString *acknowledge = nil;
	NSError *error = nil;
	NSURLResponse *response = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	if (data)
		acknowledge = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	else
		NSLog(@"*** ProVocSubmitter Error: request failed with error %@", error);
	
	if (![acknowledge isEqual:@"OK"]) {
		[self error:@"Confirmation failed"];
		return;
	}
	[self selectTabViewItemAtIndex:2];
}

-(IBAction)cancel:(id)inSender
{
	[NSApp endSheet:[self window] returnCode:NSCancelButton];
}

-(IBAction)abort:(id)inSender
{
	[mCompresser cancelCompress];
	[mUploader cancelUpload];
	mAborting = YES;
}

-(IBAction)close:(id)inSender
{
	[NSApp endSheet:[self window] returnCode:NSOKButton];
}

@end
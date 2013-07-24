//
//  ProVocInspector.h
//  ProVoc
//
//  Created by Simon Bovet on 29.03.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ARInspector.h"
#import "ProVocDocument.h";
#import "ProVocWord.h";

#define ProVocSoundDidStartPlayingNotification @"ProVocSoundDidStartPlayingNotification"
#define ProVocSoundDidStopPlayingNotification @"ProVocSoundDidStopPlayingNotification"

@class ProVocImageView, ProVocMovieView;

@interface ProVocInspector : ARInspector {
	IBOutlet NSView *mTextView;
	IBOutlet NSView *mAudioView;
	IBOutlet NSView *mImageView;
	IBOutlet NSView *mMovieView;
	
	IBOutlet ProVocImageView *mWordImageView;
	IBOutlet ProVocMovieView *mWordMovieView;
		
	ProVocDocument *mDocument;
	NSArray *mSelectedWords;
	
	NSSound *mPlayingSound;
	NSString *mPlayingSoundKey;
	ProVocWord *mPlayingSoundWord;
	
	NSMutableArray *mWordsToPlaySound;
	NSString *mSoundToPlay;
	
	BOOL mPreferredDisplayState;
}

+(ProVocInspector *)sharedInspector;

-(void)setInspectorHidden:(BOOL)inHide;
-(void)setPreferredDisplayState:(BOOL)inDisplay;

-(void)setDocument:(ProVocDocument *)inDocument;
-(void)setSelectedWords:(NSArray *)inWords;
-(void)documentParameterDidChange:(ProVocDocument *)inDocument;
-(void)selectedWordParameterDidChange:(ProVocWord *)inWord;

-(IBAction)playSourceAudio:(id)inSender;
-(IBAction)playTargetAudio:(id)inSender;

-(IBAction)importSourceAudio:(id)inSender;
-(IBAction)importTargetAudio:(id)inSender;

-(IBAction)exportSourceAudio:(id)inSender;
-(IBAction)exportTargetAudio:(id)inSender;

-(IBAction)removeSourceAudio:(id)inSender;
-(IBAction)removeTargetAudio:(id)inSender;

-(IBAction)recordSourceAudio:(id)inSender;
-(IBAction)recordTargetAudio:(id)inSender;

-(IBAction)soundInput:(id)inSender;

-(IBAction)importImage:(id)inSender;
-(IBAction)exportImage:(id)inSender;
-(IBAction)removeImage:(id)inSender;
-(IBAction)recordImage:(id)inSender;

-(IBAction)importMovie:(id)inSender;
-(IBAction)exportMovie:(id)inSender;
-(IBAction)removeMovie:(id)inSender;
-(IBAction)recordMovie:(id)inSender;

-(BOOL)handleKeyDownEvent:(NSEvent *)inEvent;

@end

@interface ProVocInspector (Media)

-(void)removeMediaOtherThan:(NSSet *)inUsedMedia;

@end

@interface ProVocInspector (Audio)

-(BOOL)canRecordAudio;
-(BOOL)canRemoveAudio:(NSString *)inKey;
-(void)playSoundFile:(NSString *)inSoundFile forAudio:(NSString *)inKey ofWord:(ProVocWord *)inWord;
-(BOOL)playNextSound;
-(void)stopPlayingSound;
-(BOOL)isPlayingAudio:(NSString *)inKey ofWord:(ProVocWord *)inWord;
-(void)setAudio:(NSString *)inKey file:(NSString *)inFile;
-(void)recordAudioImmediately:(NSString *)inKey;

@end

@interface ProVocInspector (Image)

-(void)setImage:(NSImage *)inImage;
-(void)setImageFile:(NSString *)inFile;

@end

@interface ProVocInspector (Movie)

-(void)setMovieFile:(NSString *)inFile;

@end

@interface ProVocDocument (Media)

-(NSString *)mediaPathInBundle;
-(NSString *)temporaryDirectory;
-(NSString *)pathForMediaFile:(NSString *)inName;

-(void)moveUsedMediaFromFile:(NSString *)inPath toTemporaryFolderForSaveOperation:(NSSaveOperationType)inSaveOperationType;
-(void)moveUsedMediaIntoBundle:(NSString *)inPath;

-(void)exportMedia:(NSString *)inName toFile:(NSString *)inDestination;

-(void)displayMediaOfWord:(ProVocWord *)inWord;

@end

@interface ProVocDocument (Image)

-(void)setImageFile:(NSString *)inFileName ofWord:(ProVocWord *)inWord;
-(void)setImage:(NSImage *)inImage ofWord:(ProVocWord *)inWord;
-(NSImage *)imageForMedia:(NSString *)inMedia;
-(NSImage *)imageOfWord:(ProVocWord *)inWord;

@end

@interface ProVocDocument (Movie)

-(void)setMovieFile:(NSString *)inFileName ofWord:(ProVocWord *)inWord;
-(id)movieForMedia:(NSString *)inMedia;
-(id)movieOfWord:(ProVocWord *)inWord;

@end

@interface ProVocDocument (Audio)

-(void)setAudioFile:(NSString *)inFileName forKey:(NSString *)inKey ofWord:(ProVocWord *)inWord;
-(void)playAudio:(NSString *)inKey ofWord:(ProVocWord *)inWord;
-(BOOL)isPlayingAudio:(NSString *)inKey ofWord:(ProVocWord *)inWord;
-(NSSound *)audio:(NSString *)inKey ofWord:(ProVocWord *)inWord;
-(NSSound *)audioForMedia:(NSString *)inMedia;

@end

@interface ProVocWord (Media)

-(NSMutableDictionary *)mediaDictionary;
-(void)reimportMediaFrom:(NSDictionary *)inSource;
-(void)swapSourceAndTargetMedia;
-(NSString *)mediaFileName;

@end

@interface ProVocWord (Image)

-(NSString *)imageMedia;
-(void)setImageMedia:(NSString *)inName;
-(void)exportImage:(NSDictionary *)inInfo;
-(void)removeImage;

@end

@interface ProVocWord (Movie)

-(NSString *)movieMedia;
-(void)setMovieMedia:(NSString *)inName;
-(void)exportMovie:(NSDictionary *)inInfo;
-(void)removeMovie;

@end

@interface ProVocWord (Audio)

-(NSString *)audioMediaKey:(NSString *)inKey;
-(NSString *)mediaForAudio:(NSString *)inKey;
-(void)setMedia:(NSString *)inName forAudio:(NSString *)inKey;
-(BOOL)canPlayAudio:(NSString *)inKey;
-(void)removeAudio:(NSString *)inKey;
-(void)exportAudio:(NSDictionary *)inInfo;

@end

@interface ProVocInspectorPanel : ARInspectorPanel

@end

@interface NSString (ProVocInspector)

+(NSString *)newMediaFileName:(NSString *)inKind;

@end

@interface ProVocDropView : NSView {
	IBOutlet ProVocInspector *mInspector;
	BOOL mHighlighted;
}

@end

@interface ProVocImageDropView : ProVocDropView {
}

@end

@interface ProVocMovieDropView : ProVocDropView {
}

@end

@interface NSApplication (QTKit)

-(BOOL)hasQTKit;

@end

@interface ProVocSoundDropView : NSView {
	IBOutlet ProVocInspector *mInspector;
}

@end
//
//  ProVocDocument+Presets.h
//  ProVoc
//
//  Created by Simon Bovet on 26.01.06.
//  Copyright 2006 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ProVocDocument.h"

#define PRESET_PBOARD_TYPE @"ProVocPresetRows"

@interface ProVocDocument (Presets)

-(IBAction)newPreset:(id)inSender;
-(IBAction)editPreset:(id)inSender;
-(IBAction)duplicatePreset:(id)inSender;
-(BOOL)canRemovePreset;
-(IBAction)removePreset:(id)inSender;

-(id)presets;
-(void)setPresets:(id)inPresets;

-(void)currentPresetValuesDidChange:(id)inSender;
-(void)currentPresetDidChange:(id)inSender;
-(void)presetsDidChange:(id)inSender;

-(id)presetSettings;
-(void)setPresetSettings:(id)inPresetSettings;

@end
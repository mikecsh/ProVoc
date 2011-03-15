//
//  ProVocAppDelegate.h
//  ProVoc
//
//  Created by bovet on Mon Feb 10 2003.
//  Copyright (c) 2003 Arizona Software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ProVocAppDelegate : NSDocumentController {

}
-(IBAction)showPreferences:(id)sender;
-(IBAction)checkForUpdates:(id)inSender;
-(IBAction)discoverProvoc:(id)inSender;
-(IBAction)visitHomepage:(id)inSender;
-(IBAction)reportBug:(id)inSender;
-(IBAction)downloadDocuments:(id)inSender;

-(IBAction)toggleInspector:(id)inSender;

@end

@interface NSUserDefaults (Upgrade)

-(void)upgrade;

@end

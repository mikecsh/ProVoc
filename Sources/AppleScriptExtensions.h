//
//  AppleScriptExtensions.h
//  ProVoc
//
//  Created by Simon Bovet on 31.10.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSAppleScript (HandlerCalls)
- (NSAppleEventDescriptor *) callHandler: (NSString *) handler withArguments: (NSAppleEventDescriptor *) arguments errorInfo: (NSDictionary **) errorInfo;
@end

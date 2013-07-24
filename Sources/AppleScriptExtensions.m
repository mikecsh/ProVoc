//
//  AppleScriptExtensions.m
//  ProVoc
//
//  Created by Simon Bovet on 31.10.05.
//  Copyright 2005 Arizona Software. All rights reserved.
//

#import "AppleScriptExtensions.h"


@implementation NSAppleScript (HandlerCalls)

- (NSAppleEventDescriptor *) callHandler: (NSString *) handler withArguments: (NSAppleEventDescriptor *) arguments errorInfo: (NSDictionary **) errorInfo {
    NSAppleEventDescriptor* event; 
    NSAppleEventDescriptor* targetAddress; 
    NSAppleEventDescriptor* subroutineDescriptor; 
    NSAppleEventDescriptor* result;

    /* This will be a self-targeted AppleEvent, so we need to identify ourselves using our process id */
    int pid = [[NSProcessInfo processInfo] processIdentifier];
    targetAddress = [[NSAppleEventDescriptor alloc] initWithDescriptorType: typeKernelProcessID bytes: &pid length: sizeof(pid)];
    
    /* Set up our root AppleEvent descriptor: a subroutine call (psbr) */
    event = [[NSAppleEventDescriptor alloc] initWithEventClass: 'ascr' eventID: 'psbr' targetDescriptor: targetAddress returnID: kAutoGenerateReturnID transactionID: kAnyTransactionID];
    
    /* Set up an AppleEvent descriptor containing the subroutine (handler) name */
    subroutineDescriptor = [NSAppleEventDescriptor descriptorWithString: handler];
    [event setParamDescriptor: subroutineDescriptor forKeyword: 'snam'];

    /* Add the provided arguments to the handler call */
	if (arguments)
	    [event setParamDescriptor: arguments forKeyword: keyDirectObject];
    
    /* Execute the handler */
    result = [self executeAppleEvent: event error: errorInfo];
    
    [targetAddress release];
    [event release];
    
    return result;
}

@end

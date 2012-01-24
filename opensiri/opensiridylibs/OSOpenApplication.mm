#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <substrate.h>

@class SBApplication;

extern "C" BOOL OSRespondsToCommand(NSString* command) {
    if ([[command lowercaseString] hasPrefix:@"open "] || [[command lowercaseString] hasPrefix:@"launch "]) {
        return YES;
    }
    return NO;
}

extern "C" void OSActionString(NSString *actionString) {
    actionString = [actionString lowercaseString];
    NSRange rangeOfPrefix = [actionString rangeOfString:@"open "];
    if (rangeOfPrefix.location == NSNotFound) {
        rangeOfPrefix = [actionString rangeOfString:@"launch "];
        if (rangeOfPrefix.location == NSNotFound) {
            NSLog(@"ERROR: Invalid OPEN command");
            return;
        }
    }
    NSString *application = [actionString substringFromIndex:rangeOfPrefix.location+rangeOfPrefix.length];
    NSLog(@"Looking for application:%@", application);
    NSArray *applicationArr = [[objc_getClass("SBApplicationController") sharedInstance] allApplications];
    for (SBApplication *app in applicationArr) {
        NSLog(@"Checking %@", [app bundleIdentifier]);
        if ([[(SBApplication *)app displayName] caseInsensitiveCompare:application] == NSOrderedSame) {
            NSLog(@"Found application:%@", application);
            [[objc_getClass("SBAssistantController") sharedInstance] OSdismissAssistantWithOpenIdentifier:[app bundleIdentifier]];
        }
    }
}
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>
#import "OSProtocol.h"

@class SBApplication;


@interface OSToggles : NSObject <OSPlugin> {}
@end

@implementation OSToggles

-(BOOL)OSRespondsToCommand:(NSString *)command {
    if ([[command lowercaseString] hasPrefix:@"toggle "]) {
        return YES;
    }
    return NO;
}

-(void)OSHandleCommand:(NSString *)command {
    NSString *actionString = [command lowercaseString];
    NSRange rangeOfPrefix = [actionString rangeOfString:@"toggle "];
    if (rangeOfPrefix.location == NSNotFound) {
        NSLog(@"ERROR: Invalid BRIGHTNESS command");
        return;
    }
    NSString *brightnessCommand = [actionString substringFromIndex:rangeOfPrefix.location+rangeOfPrefix.length];
    if ([brightnessCommand isEqualToString:@"data"] || [brightnessCommand isEqualToString:@"3g"]) {
        UIScreen *mainScreen = [UIScreen mainScreen];
        mainScreen.brightness = 1.0;
    }
    else if ([brightnessCommand isEqualToString:@"wi-fi"] || [brightnessCommand isEqualToString:@"internet"]) {
        [[objc_getClass("SBAssistantController") sharedInstance] dismissAssistant];
        [[objc_getClass("SBWiFiManager") sharedInstance] setWiFiEnabled:![[objc_getClass("SBWiFiManager") sharedInstance] wiFiEnabled]];
    }
    else if ([brightnessCommand isEqualToString:@"airplane mode"]) {
        UIScreen *mainScreen = [UIScreen mainScreen];
        mainScreen.brightness = 0.0;
    }
}

@end
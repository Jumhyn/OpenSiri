#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>
#import "OSProtocol.h"

@class SBApplication;


@interface OSBrightness : NSObject <OSPlugin> {}
@end

@implementation OSBrightness

-(BOOL)OSRespondsToCommand:(NSString *)command {
    if ([[command lowercaseString] hasPrefix:@"brightness "]) {
        return YES;
    }
    return NO;
}

-(void)OSHandleCommand:(NSString *)command {
    NSString *actionString = [command lowercaseString];
    NSRange rangeOfPrefix = [actionString rangeOfString:@"brightness "];
    if (rangeOfPrefix.location == NSNotFound) {
            NSLog(@"ERROR: Invalid BRIGHTNESS command");
            return;
    }
    NSString *brightnessCommand = [actionString substringFromIndex:rangeOfPrefix.location+rangeOfPrefix.length];
    if ([brightnessCommand isEqualToString:@"full"] || [brightnessCommand isEqualToString:@"max"]) {
        UIScreen *mainScreen = [UIScreen mainScreen];
        mainScreen.brightness = 1.0;
    }
    else if ([brightnessCommand isEqualToString:@"empty"] || [brightnessCommand isEqualToString:@"zero"]) {
        UIScreen *mainScreen = [UIScreen mainScreen];
        mainScreen.brightness = 0.0;
    }
}

@end
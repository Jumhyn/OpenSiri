#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>
#import "OSProtocol.h"

@class SBApplication;


@interface OSSystemCommands : NSObject <OSPlugin> {}
@end

@implementation OSSystemCommands

-(BOOL)OSRespondsToCommand:(NSString *)command {
    if ([[command lowercaseString] isEqualToString:@"re spring"] || [[command lowercaseString] isEqualToString:@"restart springboard"]) {
        return YES;
    }
    else if ([[command lowercaseString] isEqualToString:@"reboot"] || [[command lowercaseString] isEqualToString:@"restart"]) {
        return YES;
    }
    return NO;
}

-(void)OSHandleCommand:(NSString *)command {
    NSString *actionString = [command lowercaseString];
    if ([[command lowercaseString] isEqualToString:@"re spring"] || [[command lowercaseString] isEqualToString:@"restart springboard"]) {
        exit(0);
    }
    else if ([[command lowercaseString] isEqualToString:@"reboot"] || [[command lowercaseString] isEqualToString:@"restart"]) {
        [[UIApplication sharedApplication] _rebootNow];
    }
}

@end
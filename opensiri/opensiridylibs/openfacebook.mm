#import <Foundation/Foundation.h>
#import <objc/runtime.h>

extern "C" void* OSCommand() {
    return [NSArray arrayWithObjects:@"open facebook", nil];
}

extern "C" void OSAction() {
    [[objc_getClass("SBAssistantController") sharedInstance] dismissAssistantWithOpenIdentifier:@"com.facebook.Facebook"];
}
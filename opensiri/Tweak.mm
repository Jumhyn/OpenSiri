#import <dlfcn.h>
#import "opensiribundles/OSProtocol.h"

#define DYLIB_PATH @"/var/mobile/Library/OpenSiri/"
#define BUNDLE_PATH @"/var/mobile/Library/OpenSiri/Bundles/"


@interface NSObject (AddMethod)
-(NSString*)className;
@end

@interface SBAssistantController
- (void)_handleCommand:(id)arg1;
-(void)deactivate;
-(void)dismissAssistant;
@end

@interface AFSpeechToken
-(NSString*)text;
@end

@interface SBIcon
-(void)launch;
@end

@interface SBIconModel
+(SBIconModel*)sharedInstance;
-(SBIcon*)leafIconForIdentifier:(NSString*)arg1;
@end

@interface SBIconController
+(SBIconController*)sharedInstance;
-(void)_launchIcon:(id)arg1;
@end

@class SBApplication;

@interface SBUIController
+(SBUIController*)sharedInstance;
-(void)activateApplicationFromSwitcher:(SBApplication*)arg1;
@end

@interface SBApplicationController
+(SBApplicationController*)sharedInstance;
-(SBApplication*)applicationWithDisplayIdentifier:(NSString*)arg1;
@end

@interface OSControl : NSObject {}
+(NSMutableArray *)bundles;
@end


@implementation OSControl
+(NSMutableArray*)bundles {
    NSMutableArray *d = [[NSMutableArray alloc] init];
	NSFileManager *fm = [[[NSFileManager alloc] init] autorelease];

	for (NSString *p in [fm contentsOfDirectoryAtPath:BUNDLE_PATH error:nil]) {
		if ([[p pathExtension] isEqualToString:@"bundle"])
			[d addObject:p];
	}
    
    NSLog(@"Found bundles: %@", d);

	return d;
}
@end
//Much thanks to theiostream :)


%hook SBAssistantController

%new(@@:@)
-(NSString *)OSstringFromSpeechTokenArray:(NSArray*)arr {
    NSString* ret = [[[[arr objectAtIndex:0] objectAtIndex:0] objectAtIndex:0] text];
    if ([[[arr objectAtIndex:0] objectAtIndex:0] count] > 1) {
        for (int j=1; j<[[[arr objectAtIndex:0] objectAtIndex:0] count]; j++) {
            ret = [ret stringByAppendingString:@" "];
            ret = [ret stringByAppendingString:[[[[arr objectAtIndex:0] objectAtIndex:0] objectAtIndex:j] text]];
        }
    }
    for (int i=1; i<[arr count]; i++) {
        ret = [ret stringByAppendingString:@" "];
        ret = [ret stringByAppendingString:[[[[arr objectAtIndex:i] objectAtIndex:0] objectAtIndex:0] text]];
        if ([[[arr objectAtIndex:0] objectAtIndex:0] count] > 1) {
            for (int j=1; j<[[[arr objectAtIndex:i] objectAtIndex:0] count]; j++) {
                ret = [ret stringByAppendingString:@" "];
                ret = [ret stringByAppendingString:[[[[arr objectAtIndex:i] objectAtIndex:0] objectAtIndex:j] text]];
            }
        }
    }
    return ret;
}

%new(v@:@)
-(void)OShandleCustomSpeechCommand:(NSString*)command {
    for (NSString *bundleStr in [OSControl bundles]) {
        NSBundle *bundle = [NSBundle bundleWithPath:[[NSString stringWithFormat:BUNDLE_PATH] stringByAppendingString:bundleStr]];
        NSError *err;
        if (![bundle loadAndReturnError:&err]) {
            NSLog(@"ERROR -- continuing");
            continue;
        }
        Class pluginClass;
        id plugin;
        if ((pluginClass = [bundle principalClass])) {
            if ([pluginClass conformsToProtocol:@protocol(OSPlugin)]) {
                plugin = [[pluginClass alloc] init];
                [plugin OSHandleCommand:command];
            }
        }
    }
}

%new(B@:@) 
-(BOOL)OSrespondsToCustomCommand:(NSString*)command {
    for (NSString *bundleStr in [OSControl bundles]) {
        NSBundle *bundle = [NSBundle bundleWithPath:[[NSString stringWithFormat:BUNDLE_PATH] stringByAppendingString:bundleStr]];
        NSError *err;
        if (![bundle loadAndReturnError:&err]) {
            NSLog(@"ERROR -- continuing");
            continue;
        }
        Class pluginClass;
        id plugin;
        pluginClass = [bundle principalClass];
        if ([pluginClass conformsToProtocol:@protocol(OSPlugin)]) {
            plugin = [[pluginClass alloc] init];
            if ([plugin OSRespondsToCommand:command]) {
                return YES;
            }
        }
    }
    return NO;
}
//again, thank you theiostream.

- (void)assistantConnection:(id)arg1 didRecognizeSpeechPhrases:(id)arg2 correctionIdentifier:(id)arg3 {
    NSLog(@"[OpenSiri] Received speech phrases: %@", arg2);
    NSString *command = [self OSstringFromSpeechTokenArray:arg2];
    if ([self OSrespondsToCustomCommand:command]) {
        [self OShandleCustomSpeechCommand:command];
        return;
    }
    else {
        %orig;
        return;
    }
}

%new(v@:@) 
-(void)OShandleTimer:(NSTimer*)sender {
    SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:[sender userInfo]];
    [[%c(SBUIController) sharedInstance] activateApplicationFromSwitcher:app];
}

%new(v@:@) 
-(void)OSdismissAssistantWithOpenIdentifier:(NSString*)identifier {
    [self dismissAssistant];
    if ([[%c(SBAwayController) sharedAwayController] isLocked]) {
        return;
    }
    if ([identifier isEqualToString:@"com.facebook.Facebook"]) {
        if (!([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb://"]])) {
            return;
        }
    }
    if ([identifier isEqualToString:@"com.atebits.Tweetie2"]) {
        if (!([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetie://"]])) {
            return;
        }
    }
    if ([[[%c(SBUIController) sharedInstance] window] isKeyWindow]) {
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(OShandleTimer:) userInfo:identifier repeats:NO];
    }
    else {
        SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:identifier];
        [[%c(SBUIController) sharedInstance] activateApplicationFromSwitcher:app];
    }
}

%end


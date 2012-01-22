#import <dlfcn.h>

#define DYLIB_PATH @"/var/mobile/Library/OpenSiri/"

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
+(NSMutableArray *)dylibs;
@end


@implementation OSControl
+(NSMutableArray*)dylibs {
    NSMutableArray *d = [[NSMutableArray alloc] init];
	NSFileManager *fm = [[[NSFileManager alloc] init] autorelease];

	for (NSString *p in [fm contentsOfDirectoryAtPath:DYLIB_PATH error:nil]) {
		if ([[p pathExtension] isEqualToString:@"dylib"])
			[d addObject:p];
	}

	return d;
}
@end
//Much thanks to theiostream :)


%hook SBAssistantController

%new(@@:@)
-(NSString *)stringFromSpeechTokenArray:(NSArray*)arr {
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
-(void)handleCustomSpeechCommand:(NSString*)command {
    for (unsigned int i=0; i<[[OSControl dylibs] count]; i++) {
		NSLog(@"================ Crap called. Index %d; loaded %@", i, [[OSControl dylibs] objectAtIndex:i]);

		void* handle = dlopen([[[NSString stringWithFormat:DYLIB_PATH] stringByAppendingString:[[OSControl dylibs] objectAtIndex:i]] UTF8String], RTLD_LAZY);
       
        if (handle == NULL) {
			NSLog(@"[OpenSiri] 0_0 Error. Could not load dylib %@", [[OSControl dylibs] objectAtIndex:i]);
			continue;
		}
        
        NSLog(@"[OpenSiri] Loaded %@", [[OSControl dylibs] objectAtIndex:i]);

		void* cmdcallback = dlsym(handle, "OSCommand");
		if (cmdcallback == NULL) {
			NSLog(@"[OpenSiri] Error. Could not read function void* OSCommand(). Talk to the developer of %@ for troubleshooting.", [[OSControl dylibs] objectAtIndex:i]);
			return;
		}
        
        NSArray *cmdArr = (NSArray *)((void* (*)(void)) cmdcallback)();
        for (int j=0; j<[cmdArr count]; j++) {
            if ([command caseInsensitiveCompare:[cmdArr objectAtIndex:j]] == NSOrderedSame) {
                void* actioncallback = dlsym(handle, "OSAction");
                if (actioncallback == NULL) {
                    NSLog(@"[OpenSiri] Error. Could not read function void OSAction(). Talk to the developer of %@ for troubleshooting.", [[OSControl dylibs] objectAtIndex:i]);
                    return;
                }

                ((void (*)(void)) actioncallback)();
            }
        }
    }
}

%new(B@:@) 
-(BOOL)respondsToCustomCommand:(NSString*)command {
    NSLog(@"Checking support for command \"%@\"...", command);
    for (unsigned int i=0; i<[[OSControl dylibs] count]; i++) {
		NSLog(@"================ Crap called. Index %d; loaded %@", i, [[OSControl dylibs] objectAtIndex:i]);

		void* handle = dlopen([[[NSString stringWithFormat:DYLIB_PATH] stringByAppendingString:[[OSControl dylibs] objectAtIndex:i]] UTF8String], RTLD_LAZY);
       
        if (handle == NULL) {
			NSLog(@"[OpenSiri] 0_0 Error. Could not load dylib %@", [[OSControl dylibs] objectAtIndex:i]);
			continue;
		}
        
        NSLog(@"[OpenSiri] Loaded %@", [[OSControl dylibs] objectAtIndex:i]);

		void* cmdcallback = dlsym(handle, "OSCommand");
		if (cmdcallback == NULL) {
			NSLog(@"[OpenSiri] Error. Could not read function void* OSCommand(). Talk to the developer of %@ for troubleshooting.", [[OSControl dylibs] objectAtIndex:i]);
			break;
		}
        
        NSArray *cmdArr = (NSArray *)((void* (*)(void)) cmdcallback)();
        NSLog(@"Detected command \"%@\"", cmdArr);
        
        for (int j=0; j<[cmdArr count]; j++) {
            if ([command caseInsensitiveCompare:[cmdArr objectAtIndex:j]] == NSOrderedSame) {   
                NSLog(@"[OpenSiri] dybib match found");
                return YES;
            }
        }
    }
    return NO;
}
//again, thank you theiostream.

- (void)assistantConnection:(id)arg1 didRecognizeSpeechPhrases:(id)arg2 correctionIdentifier:(id)arg3 {
    AFSpeechToken *word1 = [[[(NSArray*)arg2 objectAtIndex:0] objectAtIndex:0] objectAtIndex:0];
    NSLog(@"[OpenSiri] Received speech phrases: %@", arg2);
    NSString *command = [self stringFromSpeechTokenArray:arg2];
    if ([self respondsToCustomCommand:command]) {
        [self handleCustomSpeechCommand:command];
        return;
    }
    else {
        %orig;
        return;
    }
}

%new(v@:@) 
-(void)handleTimer:(NSTimer*)sender {
    SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:[sender userInfo]];
    [[%c(SBUIController) sharedInstance] activateApplicationFromSwitcher:app];
}

%new(v@:@) 
-(void)dismissAssistantWithOpenIdentifier:(NSString*)identifier {
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
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(handleTimer:) userInfo:identifier repeats:NO];
    }
    else {
        SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:identifier];
        [[%c(SBUIController) sharedInstance] activateApplicationFromSwitcher:app];
    }
}

%end


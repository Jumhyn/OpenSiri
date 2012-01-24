#import <dlfcn.h>

#define DYLIB_PATH @"/var/mobile/Library/OpenSiri/"

typedef void* (*function)();

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
    for (unsigned int i=0; i<[[OSControl dylibs] count]; i++) {
		NSLog(@"================ Crap called. Index %d; loaded %@", i, [[OSControl dylibs] objectAtIndex:i]);

		void* handle = dlopen([[[NSString stringWithFormat:DYLIB_PATH] stringByAppendingString:[[OSControl dylibs] objectAtIndex:i]] UTF8String], RTLD_LAZY);
       
        if (handle == NULL) {
			NSLog(@"[OpenSiri] 0_0 Error. Could not load dylib %@", [[OSControl dylibs] objectAtIndex:i]);
			continue;
		}
        
        NSLog(@"[OpenSiri] Loaded %@", [[OSControl dylibs] objectAtIndex:i]);

		//void* cmdcallback = dlsym(handle, "OSCommand");
        int (*cmdcallback)(NSString*) = (int (*)(NSString*))dlsym(handle, "OSActionString");
		if (cmdcallback == NULL) {
			NSLog(@"[OpenSiri] Error. Could not read function void* OSCommand(). Talk to the developer of %@ for troubleshooting.", [[OSControl dylibs] objectAtIndex:i]);
			return;
		}
        
        BOOL respondsToCommand = cmdcallback(command);
        //for (int j=0; j<[cmdArr count]; j++) {
            if (respondsToCommand) {
                //function actionstringcallback;
                //*(void**)(&actionstringcallback) = dlsym(handle, "OSActionString");
                int (*fun)(NSString*) = (int (*)(NSString*))dlsym(handle, "OSActionString");
                if (fun == NULL) {
                    NSLog(@"[OpenSiri] Could not read function void OSActionString(). Trying OSAction();");
                    void* actioncallback = dlsym(handle, "OSAction");
                    if (actioncallback == NULL) {
                        NSLog(@"[OpenSiri] ERROR: Could not load function OSActionString() or OSAction(). Talk to the developer of %@ for troubleshooting.", [[OSControl dylibs] objectAtIndex:i]);
                        return;
                    }
                    ((void (*)(void)) actioncallback)();
                    
                }
                else {
                    fun(command);
                }
            }
        //}
    }
}

%new(B@:@) 
-(BOOL)OSrespondsToCustomCommand:(NSString*)command {
    NSLog(@"Checking support for command \"%@\"...", command);
    for (unsigned int i=0; i<[[OSControl dylibs] count]; i++) {
		NSLog(@"================ Crap called. Index %d; loaded %@", i, [[OSControl dylibs] objectAtIndex:i]);

		void* handle = dlopen([[[NSString stringWithFormat:DYLIB_PATH] stringByAppendingString:[[OSControl dylibs] objectAtIndex:i]] UTF8String], RTLD_LAZY);
       
        if (handle == NULL) {
			NSLog(@"[OpenSiri] 0_0 Error. Could not load dylib %@", [[OSControl dylibs] objectAtIndex:i]);
			continue;
		}
        
        NSLog(@"[OpenSiri] Loaded %@", [[OSControl dylibs] objectAtIndex:i]);

		//void* cmdcallback = dlsym(handle, "OSCommand");
        int (*cmdcallback)(NSString*) = (int (*)(NSString*))dlsym(handle, "OSActionString");
		if (cmdcallback == NULL) {
			NSLog(@"[OpenSiri] Error. Could not read function void* OSCommand(). Talk to the developer of %@ for troubleshooting.", [[OSControl dylibs] objectAtIndex:i]);
			break;
		}
        
        return cmdcallback(command);
        //NSArray *cmdArr = (NSArray *)((void* (*)(void)) cmdcallback)();
        
//        for (int j=0; j<[cmdArr count]; j++) {
//            if ([command caseInsensitiveCompare:[cmdArr objectAtIndex:j]] == NSOrderedSame) {   
//                NSLog(@"[OpenSiri] dybib match found");
//                return YES;
//            }
//        }
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


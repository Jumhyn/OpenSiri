#import <Foundation/Foundation.h>
#import <objc/runtime.h>

int main(int argc, char **argv, char **envp) {
	NSLog(@"lolno");
    return 0;
}


extern "C" void* OSCommand() {
    return @"open siri";
}

extern "C" void OSAction() {
	NSLog(@"OpenSiri works!");
}

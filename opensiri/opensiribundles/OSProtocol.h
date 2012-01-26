#import <Foundation/Foundation.h>

@protocol OSPlugin <NSObject>
-(BOOL)OSRespondsToCommand:(NSString *)command;
-(void)OSHandleCommand:(NSString *)command;
@end
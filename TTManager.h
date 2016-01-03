#import <Foundation/Foundation.h>

extern NSString *const kTouchTime;
extern NSString *const kTouchPoint;

@interface TTManager : NSObject

+ (instancetype)sharedInstance;
- (void)recordTouches:(NSSet *)touches;

@end

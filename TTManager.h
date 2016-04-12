#import <Foundation/Foundation.h>

extern NSString *const kTapCount;
extern NSString *const kTouchTime;
extern NSString *const kTouchPoint;
extern NSString *const kTouchKeyboard;

@interface TTManager : NSObject

+ (instancetype)sharedInstance;
- (void)recordTouches:(NSSet *)touches;

@end

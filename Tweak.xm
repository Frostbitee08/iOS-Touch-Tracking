#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <cmath>
#import <substrate.h>

#import "TTManager.h"

@interface FBExclusiveTouchGestureRecognizer
- (void)setSbWindow:(UIWindow *)object;
- (void)setTouches:(NSMutableSet *)object;
- (UIWindow *)sbWindow;
- (NSMutableSet *)touches;
- (void)customInit;
- (void)addTouches:(NSSet *)touchObjects;
- (void)fetchWindow;
@end

%hook FBExclusiveTouchGestureRecognizer

%new
- (void)customInit {
  NSArray *windows = [[UIApplication sharedApplication] windows];
  for (UIWindow *window in windows) {
    if ([window isKindOfClass:%c(SBHomeScreenWindow)]) {
      [self setSbWindow:window];
      break;
    }
  }

  NSMutableSet *touches = [[[NSMutableSet alloc] init] retain];
  [self setTouches:touches];
}

- (id)init {
  id returnValue = %orig;
  [self customInit];
  return returnValue;
}

- (id)initWithTarget:(id)arg1 action:(SEL)arg2 {
  id returnValue = %orig;
  [self customInit];
  return returnValue;
}

- (void)dealloc {
  NSMutableSet *touches = [self touches];
  [touches release];
  %orig;
}

%new
- (void)setSbWindow:(UIWindow *)object {
    objc_setAssociatedObject(self, @selector(sbWindow), object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);  
}
%new
- (void)setTouches:(NSMutableSet *)object {
     objc_setAssociatedObject(self, @selector(touches), object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new
- (UIWindow *)sbWindow {
    return objc_getAssociatedObject(self, @selector(sbWindow));
}
%new
- (NSMutableArray *)touches {
    return objc_getAssociatedObject(self, @selector(touches));
}

%new
- (void)addTouches:(NSSet *)touchObjects {
  [self fetchWindow];
  UIWindow *sbWindow = [self sbWindow];
  NSMutableSet *touches = [self touches];

  for (UITouch *touch in touchObjects) {
     CGPoint coordinate = [touch locationInView:sbWindow.rootViewController.view];
     NSValue *touchPoint = [NSValue valueWithCGPoint:coordinate];
     NSNumber *touchTime = @(touch.timestamp);
     [touches addObject:@{kTouchTime:touchTime, kTouchPoint:touchPoint}];
  }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touchObjects withEvent:(UIEvent *)arg2 {
  [[self touches] removeAllObjects];
  [self addTouches:touchObjects];
  %orig;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touchObjects withEvent:(UIEvent *)event {
  [self addTouches:touchObjects];
  %orig;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touchObjects withEvent:(UIEvent *)arg2 {
  [self addTouches:touchObjects];
  [[TTManager sharedInstance] recordTouches:[self touches]];
  %orig;
}

%new
- (void)fetchWindow {
  UIWindow *sbWindow = [self sbWindow];
  if (sbWindow) {
    return;
  }
  NSArray *windows = [[UIApplication sharedApplication] windows];
  for (UIWindow *window in windows) {
      if ([window isKindOfClass:%c(SBHomeScreenWindow)]) {
        [self setSbWindow:window];
        break;
      }
  }
}

%end

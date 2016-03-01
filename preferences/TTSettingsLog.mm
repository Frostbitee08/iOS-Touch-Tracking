@interface PSListController : UIViewController {
    NSArray *_specifiers;
}
- (id)loadSpecifiersFromPlistName:(id)arg1 target:(id)arg2;
- (id)loadSpecifiersFromPlistName:(id)arg1 target:(id)arg2 bundle:(id)arg3;
@end

@interface PSSpecifier : NSObject
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSDictionary *properties;
@end

@interface TTSettingsLogController : PSListController {
  NSString *fileContents;
}
@end

@implementation TTSettingsLogController

- (id)init {
  self = [super init];
  if (self) {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM_dd_yyyy"];

    NSString *path = [@"/var/mobile/Library/TouchTracking/" stringByAppendingString:[formatter stringFromDate:[NSDate date]]];
    path = [path stringByAppendingString:@".json"];

    NSError *error;
    fileContents = [[[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error] retain];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setTitle:@"Today"];

  CGFloat y = [UIApplication sharedApplication].statusBarFrame.size.height + 44;
  CGFloat height = [[UIScreen mainScreen] bounds].size.height - y;
  CGFloat width = [[UIScreen mainScreen] bounds].size.width;

  UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0,y,width,height)];
  [textView setText:fileContents];
  [self.view addSubview:textView];
  [self.view bringSubviewToFront:textView];
}

@end

// vim:ft=objc

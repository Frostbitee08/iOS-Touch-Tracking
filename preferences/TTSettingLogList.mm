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

@interface TTSettingLogListController : PSListController
@end

@implementation TTSettingLogListController 

- (void)viewDidLoad {
  [super viewDidLoad];
  NSLog(@"TTSettingLogList.mm");
}

@end

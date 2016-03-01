static NSString *const reuseIdentifier = @"reuseIdentifier";

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

#import "TTSettingsLogListModel.h"

@interface TTSettingsLogListController : PSListController {
  TTSettingsLogListModel *model;
  UITableView *tableView;
}
@end

@implementation TTSettingsLogListController 

- (id)init {
  self = [super init];
  if (self) {
    model = [[TTSettingsLogListModel alloc] init];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  model.navigationController = self.navigationController;
  
  CGFloat y = [UIApplication sharedApplication].statusBarFrame.size.height + 44;
  CGFloat h = [[UIScreen mainScreen] bounds].size.height - y;
  CGFloat w = [[UIScreen mainScreen] bounds].size.width; 

  tableView = [[[UITableView alloc] initWithFrame:CGRectMake(0,y,w,h)] retain];
  [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:reuseIdentifier];
  [tableView setDataSource:model];
  [tableView setDelegate:model];

  [self.view addSubview:tableView];
  [self.view bringSubviewToFront:tableView];
}

@end
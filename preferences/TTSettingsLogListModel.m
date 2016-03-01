//Constants
static NSString *const closedLogsPath = @"/var/mobile/Library/TouchTracking/Closed/";
static NSString *const reuseIdentifier = @"reuseIdentifier";
static NSString *const fileExtension  = @"json";

@interface TTSettingsSubLogController : UIViewController {
    NSString *fileContents;
    NSString *fileTitle;
}
-(id)initWithFilePath:(NSString *)path;
@end

@implementation TTSettingsSubLogController

-(id)initWithFilePath:(NSString *)path {
    self = [super init];
    if (self) {
        NSError *error;
        fileContents = [[[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error] retain];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MM_dd_yyyy"];
        
        NSString *filename = [path.lastPathComponent stringByReplacingOccurrencesOfString:[@"." stringByAppendingString:fileExtension] withString:@""];
        NSDate *date = [formatter dateFromString:filename];
        
        [formatter setDateFormat:@"MMM dd"];
        fileTitle = [formatter stringFromDate:date];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:fileTitle];
    
    CGFloat height = [[UIScreen mainScreen] bounds].size.height;
    CGFloat width = [[UIScreen mainScreen] bounds].size.width;
    
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0,0,width,height)];
    [textView setText:fileContents];
    [self.view addSubview:textView];
    [self.view bringSubviewToFront:textView];
}

@end

#import "TTSettingsLogListModel.h"

@implementation TTSettingsLogListModel {
    NSMutableArray *closedLogs;
}

- (id)init {
    self = [super init];
    if (self) {
        closedLogs = [[NSMutableArray array] retain];
        NSArray *dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:closedLogsPath error:NULL];
        [dirs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *filename = (NSString *)obj;
            if ([[filename pathExtension] isEqualToString:fileExtension]) {
                [closedLogs addObject:filename];
            }
        }];
    }
    return self;
}

- (NSString *)pathForRowAtIndexPath:(NSIndexPath *)path {
    return [closedLogsPath stringByAppendingString:closedLogs[path.row]];
}

- (NSString *)titleForRowAtIndexPath:(NSIndexPath *)path {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM_dd_yyyy"];
    
    NSString *filename = [closedLogs[path.row] stringByReplacingOccurrencesOfString:[@"." stringByAppendingString:fileExtension] withString:@""];
    NSDate *date = [formatter dateFromString:filename];
    
    [formatter setDateFormat:@"MMMM dd, yyyy"];
    return [formatter stringFromDate:date];
}



//MARK: UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return closedLogs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    [cell.textLabel setText:[self titleForRowAtIndexPath:indexPath]];
    
    return cell;
}

//MARK: UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *path = [self pathForRowAtIndexPath:indexPath];
    TTSettingsSubLogController *viewController = [[TTSettingsSubLogController alloc] initWithFilePath:path];
    
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    [self.navigationController pushViewController:viewController animated:true];
}

@end

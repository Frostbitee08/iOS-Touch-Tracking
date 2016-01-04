#import "TTManager.h"

NSString *const kTouchTime  = @"t";
NSString *const kTouchPoint = @"p";

static NSString *const masterDirectoryPath = @"/var/mobile/Library/TouchTracking/";
static NSString *const closedDirectoryName = @"Closed";
static NSString *const fileExtension = @".json";
static const char * queueTitle = "ttq";

@implementation TTManager

- (instancetype)init {
    self = [super init];
    if (self) {
        //Ensure Directories Exist
        [self createDirectoryAtPath:masterDirectoryPath];
        [self createDirectoryAtPath:[masterDirectoryPath stringByAppendingString:closedDirectoryName]];
        
        //Ensure there is a file to write to
        [self createWriteFile];
    }
    return self;
}

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static TTManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)createDirectoryAtPath:(NSString *)path {
    BOOL isDir;
    if (!([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir)) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&error];
    }
}

- (void)createWriteFile {
    NSString *filePath = [self filePathForDate:[NSDate date]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSDictionary *attributes = @{NSFilePosixPermissions:[NSNumber numberWithShort:0777]};
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:[self openingFileContents] attributes:attributes];
        
        NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:masterDirectoryPath error:NULL];
        NSMutableArray *closedFiles = [[NSMutableArray alloc] init];
        [dirs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *filename = (NSString *)obj;
            if (![[filePath lastPathComponent] isEqualToString:filename] && ![closedDirectoryName isEqualToString:filename]) {
                [closedFiles addObject:filename];
            }
        }];
        
        for (NSString *filename in closedFiles) {
            [self closeFileWithName:filename];
        }
    }
}

- (void)closeFileWithName:(NSString *)filename {
    NSString *closedDirectoryPath = [NSString stringWithFormat:@"%@%@/", masterDirectoryPath, closedDirectoryName];
    NSString *source = [masterDirectoryPath stringByAppendingString:filename];
    NSString *destination =[closedDirectoryPath stringByAppendingString:filename];
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:source];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[self closingFileContents]];
    [fileHandle closeFile];
    
    [[NSFileManager defaultManager] moveItemAtPath:source toPath:destination error:nil];
}

- (NSData *)openingFileContents {
    NSString *openingString = @"[\n";
    return [openingString dataUsingEncoding:NSUTF8StringEncoding];;
}
             
- (NSData *)closingFileContents {
    NSString *closingString = @"]";
    return [closingString dataUsingEncoding:NSUTF8StringEncoding];;
}

- (NSString *)filePathForDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM_dd_yyyy"];
    
    NSString *path = [masterDirectoryPath stringByAppendingString:[formatter stringFromDate:date]];
    NSString *pathWithFileExtension = [path stringByAppendingString:fileExtension];
    
    return pathWithFileExtension;
}

- (void)recordTouches:(NSSet *)touches {
    dispatch_queue_t queue = dispatch_queue_create(queueTitle, 0);
    dispatch_async(queue, ^{
        if (touches.allObjects.count) {
            [self createWriteFile];
            
            NSMutableString *writeString = [[NSMutableString alloc] init];
            [writeString appendString:@"\t{\n"];
            [writeString appendString:@"\t\t\"T\" : [\n"];
            
            for (NSDictionary *touch in touches.allObjects) {
                NSTimeInterval systemUptime = [[NSProcessInfo processInfo] systemUptime];
                NSTimeInterval touchTime = [touch[kTouchTime] doubleValue];
                double difference = systemUptime-touchTime;
                
                NSDate *touchDate = [[NSDate alloc] initWithTimeIntervalSinceNow:difference];
                NSTimeInterval secondsSinceMidnight = [touchDate timeIntervalSinceDate:[[NSCalendar currentCalendar] startOfDayForDate:touchDate]];
                CGPoint coorindate = [touch[kTouchPoint] CGPointValue];
                
                NSMutableString *touchString = [NSMutableString stringWithFormat:@"\t\t\t{\"t\":%f, \"x\":%f, \"y\":%f}", secondsSinceMidnight, coorindate.x, coorindate.y];
                if (touch == [touches.allObjects lastObject]) {
                    [touchString appendString:@"\n"];
                }
                else {
                    [touchString appendString:@",\n"];
                }
                [writeString appendString:touchString];
                
            }
            [writeString appendString:@"\t\t]\n"];
            [writeString appendString:@"\t},\n"];
            
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:[self filePathForDate:[NSDate date]]];
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:[writeString dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle closeFile];
        }
    });
}

@end

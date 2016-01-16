#import "TTManager.h"
#import "Reachability.h"
#import "preferences/TTSettingsManager.h"
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>

//URLS
static NSString *const gourl = @"http://159.203.78.76:8000";

//Keys
NSString *const kTouchTime         = @"t";
NSString *const kTouchPoint        = @"p";
static NSString *const kFilename   = @"filename";
static NSString *const kIdentifier = @"identifier";

//Constants
static NSString *const masterDirectoryPath = @"/var/mobile/Library/TouchTracking/";
static NSString *const closedDirectoryName = @"Closed";
static NSString *const fileExtension       = @".json";
static const char * queueTitle             = "ttq";

@interface NSString (MD5)
- (NSString *)md5;
@end

@implementation NSString (MD5)

- (NSString *)md5 {
    const char *cstr = [self UTF8String];
    unsigned char result[16];
    CC_MD5(cstr, strlen(cstr), result);

    return [NSString stringWithFormat:
        @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
        result[0], result[1], result[2], result[3], 
        result[4], result[5], result[6], result[7],
        result[8], result[9], result[10], result[11],
        result[12], result[13], result[14], result[15]
    ];  
}

@end

@implementation TTManager {
    Reachability *reachability;
    BOOL isFreshlyOpened;
}

//MARK: Intiitalzers
  
- (instancetype)init {
    self = [super init];
    if (self) {
        //Setup Network Reachabiluty
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadClosedFiles) name:kReachabilityChangedNotification object:nil];
        reachability = [[Reachability reachabilityForInternetConnection] retain];
        [reachability startNotifier];

        //Ensure Directories Exist
        [self createDirectoryAtPath:masterDirectoryPath];
        [self createDirectoryAtPath:[masterDirectoryPath stringByAppendingString:closedDirectoryName]];
        
        //Ensure there is a file to write to
        [self createWriteFile];
        [self uploadClosedFiles];
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

- (void)dealloc {
  [reachability release];
  [super dealloc];
}

- (void)createDirectoryAtPath:(NSString *)path {
    BOOL isDir;
    if (!([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir)) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&error];
    }
}

//MARK: Creating Logs

- (void)createWriteFile {
    NSString *filePath = [self filePathForDate:[NSDate date]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSDictionary *attributes = @{NSFilePosixPermissions:[NSNumber numberWithShort:0777]};
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:[@"[\n" dataUsingEncoding:NSUTF8StringEncoding] attributes:attributes];
        
        isFreshlyOpened = TRUE;
        [self closeFiles];
    }
}

//MARK: Closing Logs

- (void)closeFiles {
    NSArray *dirs               = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:masterDirectoryPath error:NULL];
    NSString *filePath          = [self filePathForDate:[NSDate date]];
    NSMutableArray *closedFiles = [[NSMutableArray alloc] init];
    
    [dirs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *filename = (NSString *)obj;
        if (![[filePath lastPathComponent] isEqualToString:filename] && ![closedDirectoryName isEqualToString:filename]) {
            [closedFiles addObject:filename];
        }
    }];
    
    if (closedFiles.count) {
        for (NSString *filename in closedFiles) {
            [self closeFileWithName:filename];
        }
        [self uploadClosedFiles];
    }
}

- (void)closeFileWithName:(NSString *)filename {
    NSString *closedDirectoryPath = [NSString stringWithFormat:@"%@%@/", masterDirectoryPath, closedDirectoryName];
    NSString *source              = [masterDirectoryPath stringByAppendingString:filename];
    NSString *destination         = [closedDirectoryPath stringByAppendingString:filename];
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:source];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[@"\n]" dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle closeFile];
    
    [[NSFileManager defaultManager] moveItemAtPath:source toPath:destination error:nil];
}

//MARK: Uploading Files

- (void)uploadClosedFiles {
    //Ensure We have Connection
    //Ensure we are allowed to upload
    //Ensure we are allowed to upload if connection is cellular
    if (reachability.currentReachabilityStatus == 0) return;
    if (![[TTSettingsManager sharedInstance] isUploadEnabled]) return;
    if (reachability.currentReachabilityStatus == 2 && ![[TTSettingsManager sharedInstance] isCellularUploadEnabled]) return;
    
    //Upload Stuff
    NSString *closedDirectoryPath = [NSString stringWithFormat:@"%@%@/", masterDirectoryPath, closedDirectoryName];
    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:closedDirectoryPath error:NULL];
    [dirs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *filename = (NSString *)obj;
        [self uploadFileWithName:filename];
    }];
}

- (void)uploadFileWithName:(NSString *)filename {
    NSString *closedDirectoryPath = [NSString stringWithFormat:@"%@%@/", masterDirectoryPath, closedDirectoryName];
    NSString *source              = [closedDirectoryPath stringByAppendingString:filename];
    NSString *deviceName          = [[UIDevice currentDevice] name];
    NSString *uniqueId            = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSString *identifier          = [[deviceName stringByAppendingString:uniqueId] md5];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:gourl]];
    [request setHTTPMethod:@"POST"];
    [request addValue:identifier forHTTPHeaderField:kIdentifier];
    [request addValue:filename forHTTPHeaderField:kFilename];
    [request setHTTPBody:[NSData dataWithContentsOfFile:source]];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"TT Uploaded File %@ RESPONSE: %@", filename, newStr);
        
        if ([[TTSettingsManager sharedInstance] isDeleteLogsEnabled] && !error) {
            [[NSFileManager defaultManager] removeItemAtPath:source error:&error];
        }
    }] resume]; 

}

//MARK: Accessors

- (NSString *)filePathForDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM_dd_yyyy"];
    
    NSString *path                  = [masterDirectoryPath stringByAppendingString:[formatter stringFromDate:date]];
    NSString *pathWithFileExtension = [path stringByAppendingString:fileExtension];
    
    return pathWithFileExtension;
}

//MARK: Actions

- (void)recordTouches:(NSSet *)touches {
    if ([[TTSettingsManager sharedInstance] isTrackingEnabled]) {
        dispatch_queue_t queue = dispatch_queue_create(queueTitle, 0);
        dispatch_barrier_async(queue, ^{
            if (touches.count) {
                [self createWriteFile];
                NSMutableString *writeString = [[NSMutableString alloc] init];
                
                if (!isFreshlyOpened) [writeString appendString:@",\n"];
                else                  [writeString appendString:@"\n"];
                [writeString appendString:@"\t{\n"];
                [writeString appendString:@"\t\t\"T\" : [\n"];
                
                for (NSDictionary *touch in touches) {
                    NSTimeInterval systemUptime = [[NSProcessInfo processInfo] systemUptime];
                    NSTimeInterval touchTime    = [touch[kTouchTime] doubleValue];
                    double difference           = systemUptime-touchTime;
                    
                    NSDate *touchDate                   = [[NSDate alloc] initWithTimeIntervalSinceNow:difference];
                    NSTimeInterval secondsSinceMidnight = [touchDate timeIntervalSinceDate:[[NSCalendar currentCalendar] startOfDayForDate:touchDate]];
                    CGPoint coorindate                  = [touch[kTouchPoint] CGPointValue];
                    
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
                [writeString appendString:@"\t}"];
                
                NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:[self filePathForDate:[NSDate date]]];
                [fileHandle seekToEndOfFile];
                [fileHandle writeData:[writeString dataUsingEncoding:NSUTF8StringEncoding]];
                [fileHandle closeFile];
            }

            isFreshlyOpened = FALSE;
        });
    }
}

@end

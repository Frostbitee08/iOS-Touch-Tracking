#import "TTManager.h"
#import "Reachability.h"
#import "preferences/TTSettingsManager.h"
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>

//URLS
static NSString *const gourl = @"http://159.203.78.76:8000";

//Keys
NSString *const kTapCount          = @"tc";
NSString *const kTouchTime         = @"t";
NSString *const kTouchPoint        = @"p";
NSString *const kTouchKeyboard     = @"kb";
static NSString *const kFilename   = @"filename";
static NSString *const kIdentifier = @"identifier";

//Constants
static NSString *const masterDirectoryPath   = @"/var/mobile/Library/TouchTracking/";
static NSString *const closedDirectoryName   = @"Closed";
static NSString *const uploadedDirectoryName = @"Uploaded";
static NSString *const fileExtension         = @".json";
static const char * writeQueueTitle          = "wttq";
static const char * uploadQueueTitle         = "uttq";

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
    dispatch_queue_t writeQueue;
    dispatch_queue_t uploadQueue;
    Reachability *reachability;
    BOOL isFreshlyOpened;
}

//MARK: Intiitalzers
  
- (instancetype)init {
    self = [super init];
    if (self) {
        //Initialize Queues
        writeQueue = dispatch_queue_create(writeQueueTitle, 0);
        uploadQueue = dispatch_queue_create(uploadQueueTitle, 0);
        
        //Setup Network Reachabiluty
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadClosedFiles) name:kReachabilityChangedNotification object:nil];
        reachability = [[Reachability reachabilityForInternetConnection] retain];
        [reachability startNotifier];

        //Ensure Directories Exist [self createDirectoryAtPath:masterDirectoryPath];
        [self createDirectoryAtPath:[masterDirectoryPath stringByAppendingString:closedDirectoryName]];
        [self createDirectoryAtPath:[NSString stringWithFormat:@"%@%@/%@", masterDirectoryPath, closedDirectoryName, uploadedDirectoryName]];
        
        //Ensure there is a file to write to
        [self uploadClosedFiles];
        dispatch_barrier_async(writeQueue, ^{
            [self createWriteFile];
        });
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
    if (0) {
        [reachability release];
        [super dealloc];
    }
}

- (void)createDirectoryAtPath:(NSString *)path {
    BOOL isDir = NO;
    if (!([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir)) {
        NSError *error = NULL;
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
    NSMutableArray *closedFiles = [NSMutableArray array];
    
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
        [self uploadFileWithName:obj];
    }];
    
    //Delete Old Stuff
    if ([[TTSettingsManager sharedInstance] isDeleteLogsEnabled]) {
        NSString *uploadedDirectoryPath = [NSString stringWithFormat:@"%@%@/%@/", masterDirectoryPath, closedDirectoryName, uploadedDirectoryName];
        NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:uploadedDirectoryPath error:NULL];
        NSMutableArray *delete = [NSMutableArray array];
        [dirs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [delete addObject:[uploadedDirectoryPath stringByAppendingString:obj]];
        }];
        for (NSString *path in delete) {
            NSError *deleteError = [[NSError alloc] init];
            [[NSFileManager defaultManager] removeItemAtPath:path error:&deleteError];
        }
    }
}

- (void)uploadFileWithName:(NSString *)incomingFilename {
    NSString *filename = [incomingFilename copy];
    dispatch_async(uploadQueue, ^(void) {
        NSString *closedDirectoryPath = [NSString stringWithFormat:@"%@%@/", masterDirectoryPath, closedDirectoryName];
        NSString *source              = [closedDirectoryPath stringByAppendingString:filename];
        NSString *deviceName          = [[UIDevice currentDevice] name];
        NSString *uniqueId            = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        
        if (deviceName == nil || uniqueId == nil) {
          [filename release];
          return;
        }

        NSString *identifier          = [[deviceName stringByAppendingString:uniqueId] md5];
        NSInputStream *input          = [[NSInputStream alloc] initWithFileAtPath:source];

        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:gourl]];
        [request setHTTPMethod:@"POST"];
        [request addValue:identifier forHTTPHeaderField:kIdentifier];
        [request addValue:filename forHTTPHeaderField:kFilename];
        [request setHTTPBodyStream:input];
        //[request setHTTPBody:[NSData dataWithContentsOfFile:source]];
        
        [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"TT Uploaded File %@ RESPONSE: %@", filename, newStr);
            
            dispatch_barrier_async(writeQueue, ^{
                if ([[TTSettingsManager sharedInstance] isDeleteLogsEnabled] && !error) {
                  NSError *deleteError = [[NSError alloc] init];
                  [[NSFileManager defaultManager] removeItemAtPath:source error:&deleteError];
                }
                else if (!error) {
                    NSString *uploadedDirectoryPath = [NSString stringWithFormat:@"%@%@/%@/", masterDirectoryPath, closedDirectoryName, uploadedDirectoryName];
                    NSString *destination           = [uploadedDirectoryPath stringByAppendingString:filename];
                    
                    [[NSFileManager defaultManager] moveItemAtPath:source toPath:destination error:nil];
                }
            }); 
        }] resume];
        [filename release];
    });
}

//MARK: Accessors

- (NSString *)filePathForDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM_dd_yyyy"];
    
    NSString *path                  = [masterDirectoryPath stringByAppendingString:[formatter stringFromDate:date]];
    NSString *pathWithFileExtension = [[path stringByAppendingString:fileExtension] retain];
    
    [formatter release];
    return [pathWithFileExtension autorelease];
}

//MARK: Actions

- (void)recordTouches:(NSSet *)incomingTouches {
    NSSet *touches = [incomingTouches copy];
    if ([[TTSettingsManager sharedInstance] isTrackingEnabled]) {
        dispatch_barrier_async(writeQueue, ^{
            if (touches.count) {
                [self createWriteFile];
                NSMutableString *writeString = [[NSMutableString alloc] init];
                
                if (!isFreshlyOpened) [writeString appendString:@",\n"];
                else                  [writeString appendString:@"\n"];
                [writeString appendString:@"\t{\n"];
                [writeString appendString:@"\t\t\"T\" : [\n"];

                NSArray *sortedTouches = [[touches allObjects] sortedArrayUsingComparator: ^(NSDictionary *one, NSDictionary *two) {
                    NSTimeInterval first = [one[kTouchTime] doubleValue];
                    NSTimeInterval second = [two[kTouchTime] doubleValue];

                    if (first == second) {
                        return NSOrderedSame;
                    }
                    else if (first < second) {
                        return NSOrderedAscending;
                    }
                    return NSOrderedDescending; 
                }];
                
                NSTimeInterval firstTouch = -1;;
                for (NSDictionary *touch in sortedTouches) {
                    NSInteger tapCount = [touch[kTapCount] integerValue];
                    CGPoint coorindate = [touch[kTouchPoint] CGPointValue];
                    BOOL keyboardTouch = [touch[kTouchKeyboard] boolValue];
                    NSTimeInterval time = [touch[kTouchTime] doubleValue];
                    NSTimeInterval touchTime = 0;

                    if (keyboardTouch == true && ![[TTSettingsManager sharedInstance] isKeyboardTrackingEnabled]) {
                      continue;
                    }

                    if (firstTouch == -1) {
                      firstTouch = time;
                    }
                    else {
                      touchTime = time-firstTouch;
                    }
                    
                    NSMutableString *touchString = [NSMutableString stringWithFormat:@"\t\t\t{\"t\":%f, \"tc\":%li, \"kb\":%d, \"x\":%f, \"y\":%f}", touchTime, (long)tapCount, keyboardTouch, coorindate.x, coorindate.y];
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
                
                [writeString release];
            }

            isFreshlyOpened = FALSE;
            [touches release];
        });
    }
}

@end

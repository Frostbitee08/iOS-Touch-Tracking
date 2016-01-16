#import <Foundation/Foundation.h>

extern NSString *const settingsFilePath;

@interface TTSettingsManager : NSObject

+ (instancetype)sharedInstance;

- (BOOL)isTrackingEnabled;
- (BOOL)isCellularUploadEnabled;
- (BOOL)isUploadEnabled;
- (BOOL)isDeleteLogsEnabled;

- (void)reloadSettings;

@end

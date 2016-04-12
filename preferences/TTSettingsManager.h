#import <Foundation/Foundation.h>

extern NSString *const settingsFilePath;

@interface TTSettingsManager : NSObject

+ (instancetype)sharedInstance;

- (BOOL)isTrackingEnabled;
- (BOOL)isCellularUploadEnabled;
- (BOOL)isUploadEnabled;
- (BOOL)isDeleteLogsEnabled;
- (BOOL)isKeyboardTrackingEnabled;

- (void)reloadSettings;

@end

//Constants
NSString *const settingsFilePath = @"/var/mobile/Library/Preferences/com.roccodeplriore.touchtracking.settings.plist";

//Keys
NSString *const kTrackingEnabled = @"TrackingEnabled";
NSString *const kUploadEnabled = @"UploadEnabled";
NSString *const kCellularUploadEnabled = @"CellularUploadEnabled";
NSString *const kDeleteLogsEnabled = @"DeleteLogsEnabled";

#import "TTSettingsManager.h"

@implementation TTSettingsManager {
    NSDictionary *settings;
}

//MARK: Intializers

- (instancetype)init {
    self = [super init];
    if (self) {
        settings = [[NSDictionary dictionary] retain];
        [self reloadSettings];
    }
    return self;
}

+ (instancetype)sharedInstance {
    static dispatch_once_t pred;
    static TTSettingsManager *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)dealloc {
  [super dealloc];
  [settings release];
}

//MARK: Accessors

- (BOOL)isTrackingEnabled {
  return [settings[kTrackingEnabled] boolValue];
}

- (BOOL)isUploadEnabled {
  return [settings[kUploadEnabled] boolValue];
}

- (BOOL)isCellularUploadEnabled {
  return [settings[kCellularUploadEnabled] boolValue];
}

- (BOOL)isDeleteLogsEnabled {
  return [settings[kDeleteLogsEnabled] boolValue];
}

//MARK: Actions

- (void)reloadSettings {
    settings = [[NSDictionary dictionaryWithContentsOfFile:settingsFilePath] retain];
}

@end

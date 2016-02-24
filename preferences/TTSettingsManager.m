//Constants
NSString *const settingsFilePath = @"/var/mobile/Library/Preferences/com.roccodeplriore.touchtracking.settings.plist";

//Keys
NSString *const kTrackingEnabled       = @"TrackingEnabled";
NSString *const kUploadEnabled         = @"UploadEnabled";
NSString *const kCellularUploadEnabled = @"CellularUploadEnabled";
NSString *const kDeleteLogsEnabled     = @"DeleteLogsEnabled";

#import "TTSettingsManager.h"

@interface TTSettingsManager ()
@property (atomic, retain) NSDictionary *settings;
@end

@implementation TTSettingsManager

//MARK: Intializers

- (instancetype)init {
    self = [super init];
    if (self) {
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
    self.settings = nil;
    [super dealloc];
}

//MARK: Accessors

- (BOOL)isTrackingEnabled {
  return [self.settings[kTrackingEnabled] boolValue];
}

- (BOOL)isUploadEnabled {
  return [self.settings[kUploadEnabled] boolValue];
}

- (BOOL)isCellularUploadEnabled {
  return [self.settings[kCellularUploadEnabled] boolValue];
}

- (BOOL)isDeleteLogsEnabled {
  return [self.settings[kDeleteLogsEnabled] boolValue];
}

//MARK: Actions

- (void)reloadSettings {
    self.settings = [NSDictionary dictionaryWithContentsOfFile:settingsFilePath];
}

@end

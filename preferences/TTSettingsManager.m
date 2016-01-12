//Constants
NSString *const settingsFilePath = @"/var/mobile/Library/Preferences/com.roccodeplriore.touchtracking.settings.plist";

//Keys
NSString *const kTrackingEnabled = @"TrackingEnabled";

#import "TTSettingsManager.h"

@implementation TTSettingsManager {
    NSDictionary *settings;
}

//MARK: Intializers

- (instancetype)init {
    self = [super init];
    if (self) {
        settings = [NSDictionary dictionary];
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

//MARK: Accessors

- (BOOL)isTrackingEnabled {
  //Accessing settings after initial call crashes without reloading
  //Settings is not nil, or NULL in this occurnace
  //No idea why it is happening
  [self reloadSettings];
  return [settings[kTrackingEnabled] boolValue];
}

//MARK: Actions

- (void)reloadSettings {
    settings = [NSDictionary dictionaryWithContentsOfFile:settingsFilePath];
}

@end

//Constants
static NSString *const specifiersFileName = @"TTSettings";

//Keys
static NSString *const kKey = @"key";
static NSString *const kDefaults = @"default";

#import "TTSettingsManager.h"

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

@interface TTSettingsListController: PSListController {
    NSString *preferencesPath;
}
@end

@implementation TTSettingsListController

- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = [[self loadSpecifiersFromPlistName:specifiersFileName target:self] retain];
    }
    return _specifiers;
}

-(id)readPreferenceValue:(PSSpecifier*)specifier {
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:settingsFilePath];
    if (!settings[specifier.properties[kKey]]) return specifier.properties[kDefaults];
    return settings[specifier.properties[kKey]];
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    [defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:settingsFilePath]];
    [defaults setObject:value forKey:specifier.properties[kKey]];
    [defaults writeToFile:settingsFilePath atomically:YES];
    [[TTSettingsManager sharedInstance] reloadSettings];
}

@end

// vim:ft=objc

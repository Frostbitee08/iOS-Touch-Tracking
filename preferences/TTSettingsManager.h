//
//  TTSettingsManager.h
//  
//
//  Created by Rocco Del Priore on 1/6/16.
//
//

#import <Foundation/Foundation.h>

extern NSString *const settingsFilePath;

@interface TTSettingsManager : NSObject

+ (instancetype)sharedInstance;

- (BOOL)isTrackingEnabled;

- (void)reloadSettings;

@end

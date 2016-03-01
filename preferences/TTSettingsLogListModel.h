//
//  TTSettingsLogListModel.h
//  
//
//  Created by Rocco Del Priore on 3/1/16.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TTSettingsLogListModel : NSObject <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) UINavigationController *navigationController;

- (NSString *)pathForRowAtIndexPath:(NSIndexPath *)path;

@end

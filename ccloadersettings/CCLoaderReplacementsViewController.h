//
//  CCLoaderReplacementsViewController.h
//  CCLoader Settings
//
//  Created by Jonas Gessner on 04.01.2014.
//  Copyright (c) 2014 Jonas Gessner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CCLoaderReplacementsViewController : UITableViewController

- (instancetype)initWithReplacements:(NSDictionary *)replacements selected:(NSString *)currentSelected orderedKeys:(NSArray *)ordered selectedCallback:(void (^)(NSString *selected))callback;

@end

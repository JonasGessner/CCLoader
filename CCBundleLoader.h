//
//  CCBundleLoader.h
//  CCLoader
//
//  Created by Jonas Gessner on 04.01.2014.
//  Copyright (c) 2014 Jonas Gessner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CCBundleLoader : NSObject

+ (instancetype)sharedInstance;

- (void)loadBundles;

@property (nonatomic, strong, readonly) NSSet *bundles;

@end
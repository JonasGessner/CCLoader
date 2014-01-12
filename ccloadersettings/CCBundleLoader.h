//
//  CCBundleLoader.h
//  CCLoader
//
//  Created by Jonas Gessner on 04.01.2014.
//  Copyright (c) 2014 Jonas Gessner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define kCCLoaderReplaceStockSectionInfoDicationaryKey @"CCReplacingStockSectionID"

#define kCCLoaderStockOrderedSections @[@"com.apple.controlcenter.settings", @"com.apple.controlcenter.brightness", @"com.apple.controlcenter.media-controls", @"com.apple.controlcenter.air-stuff", @"com.apple.controlcenter.quick-launch"]

#define kCCLoaderStockSections [NSSet setWithArray:kCCLoaderStockOrderedSections]

@interface CCBundleLoader : NSObject

+ (instancetype)sharedInstance;

- (void)loadBundles;
- (void)unloadBundles;

@property (nonatomic, strong, readonly) NSSet *bundles;
@property (nonatomic, strong, readonly) NSDictionary *replacingBundles;


@end
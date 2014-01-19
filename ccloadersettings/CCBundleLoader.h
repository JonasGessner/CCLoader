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

#define ARC __has_feature(objc_arc)

#if ARC
#define CC_STRONG strong
#else
#define CC_STRONG retain
#endif

@interface CCBundleLoader : NSObject

+ (instancetype)sharedInstance;

- (void)loadBundlesAndReplacements:(BOOL)alsoLoadReplacementBundles loadNames:(BOOL)names checkBundles:(BOOL)check;

- (void)unloadBundles;


@property (nonatomic, CC_STRONG, readonly) NSDictionary *displayNames;


@property (nonatomic, CC_STRONG, readonly) NSSet *oldNCBundles;

@property (nonatomic, CC_STRONG, readonly) NSSet *NCBundles;

@property (nonatomic, CC_STRONG, readonly) NSSet *NCBundleIDs;



@property (nonatomic, CC_STRONG, readonly) NSSet *bundles;

@property (nonatomic, CC_STRONG, readonly) NSDictionary *replacingBundles;


/*
 @return All the bundle IDs of the bundles stored in \c bundles.
 @warning Does not contain any bundle IDs of \c replacingBundles.
 */
@property (nonatomic, CC_STRONG, readonly) NSSet *bundleIDs;



@end
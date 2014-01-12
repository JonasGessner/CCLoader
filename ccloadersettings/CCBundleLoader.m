//
//  CCBundleLoader.m
//  CCLoader
//
//  Created by Jonas Gessner on 04.01.2014.
//  Copyright (c) 2014 Jonas Gessner. All rights reserved.
//

#import "CCBundleLoader.h"

#import "CCSection-Protocol.h"


#define kCCSectionBundlePath @"/Library/CCLoader/Bundles"

@implementation CCBundleLoader

+ (instancetype)sharedInstance {
    static CCBundleLoader *instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

- (void)loadBundles {
    NSMutableSet *bundles = [NSMutableSet set];
    
    NSMutableDictionary *replacingBundles = [NSMutableDictionary dictionary];
    
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:kCCSectionBundlePath error:nil];
    
    NSSet *stockSections = kCCLoaderStockSections;
    
    for (NSString *file in contents) {
        if ([file.pathExtension isEqualToString:@"bundle"]) {
            NSString *path = [kCCSectionBundlePath stringByAppendingPathComponent:file];
            
            NSBundle *bundle = [NSBundle bundleWithPath:path];
            
            Class principalClass = [bundle principalClass];
            
            if ([principalClass conformsToProtocol:@protocol(CCSection)]) {
                NSString *replaceID = [bundle objectForInfoDictionaryKey:kCCLoaderReplaceStockSectionInfoDicationaryKey];
                
                if ([stockSections containsObject:replaceID]) {
                    replacingBundles[replaceID] = bundle;
                }
                else {
                    [bundles addObject:bundle];
                }
            }
        }
    }
    
    if (replacingBundles.count) {
        _replacingBundles = replacingBundles.copy;
    }
    
    if (bundles.count) {
        _bundles = bundles.copy;
    }
}

- (void)unloadBundles {
    _bundles = nil;
    _replacingBundles = nil;
}


@end
//
//  CCBundleLoader.m
//  CCLoader
//
//  Created by Jonas Gessner on 04.01.2014.
//  Copyright (c) 2014 Jonas Gessner. All rights reserved.
//

#import "CCBundleLoader.h"

#import "CCSection-Protocol.h"


#define kSectionBundlePath @"/Library/CCLoader/Bundles"

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
    
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:kSectionBundlePath error:nil];
    
    for (NSString *file in contents) {
        if ([file.pathExtension isEqualToString:@"bundle"]) {
            NSString *path = [kSectionBundlePath stringByAppendingPathComponent:file];
            
            NSBundle *bundle = [NSBundle bundleWithPath:path];
            
            Class principal = [bundle principalClass];
            
            if ([principal conformsToProtocol:@protocol(CCSection)]) {
                [bundles addObject:bundle];
            }
        }
    }
    
    if (bundles.count) {
        _bundles = bundles.copy;
    }
}

- (void)unloadBundles {
    _bundles = nil;
}


@end
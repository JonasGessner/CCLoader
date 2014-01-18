//
//  CCBundleLoader.m
//  CCLoader
//
//  Created by Jonas Gessner on 04.01.2014.
//  Copyright (c) 2014 Jonas Gessner. All rights reserved.
//

#import "CCBundleLoader.h"

#import "CCSection-Protocol.h"

#import "BBWeeAppController-Protocol.h"

#import "SpringBoardUIServices/_SBUIWidgetViewController.h"

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

- (void)loadNCBundles {
    NSString *bundlePath = @"/System/Library/WeeAppPlugins";
    
    NSString *bundlePath2 = @"/Library/WeeLoader/Plugins";
    
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:bundlePath error:nil];
    
    NSArray *contents2 = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:bundlePath2 error:nil];
    
    NSMutableSet *oldBundles = [NSMutableSet set];
    
    NSMutableSet *newBundles = [NSMutableSet set];
    
    NSMutableSet *IDs = [NSMutableSet set];
    
    for (NSString *file in contents) {
        if ([file.pathExtension isEqualToString:@"bundle"]) {
            NSString *path = [bundlePath stringByAppendingPathComponent:file];
            
            NSBundle *bundle = [NSBundle bundleWithPath:path];
            
            Class principalClass = [bundle principalClass];
            
            NSLog(@"CLASSSS %@ %@", principalClass, bundle);
            
            if ([principalClass conformsToProtocol:@protocol(BBWeeAppController)]) {
                [IDs addObject:bundle.bundleIdentifier];
                
                [oldBundles addObject:bundle];
            }
            else if ([principalClass isKindOfClass:[_SBUIWidgetViewController class]]) {
                [IDs addObject:bundle.bundleIdentifier];
                
                [newBundles addObject:bundle];
            }
            else {
                //You gotta fix that penguin bro!
                //..
                //..
                //Nope!
            }
            
            [bundle unload];
        }
    }
    
    for (NSString *file in contents2) {
        if ([file.pathExtension isEqualToString:@"bundle"]) {
            NSString *path = [bundlePath2 stringByAppendingPathComponent:file];
            
            NSBundle *bundle = [NSBundle bundleWithPath:path];
            
            Class principalClass = [bundle principalClass];
            
            if ([principalClass conformsToProtocol:@protocol(BBWeeAppController)]) {
                [IDs addObject:bundle.bundleIdentifier];
                
                [oldBundles addObject:bundle];
            }
            else if ([principalClass isKindOfClass:[_SBUIWidgetViewController class]]) {
                [IDs addObject:bundle.bundleIdentifier];
                
                [newBundles addObject:bundle];
            }
            else {
                //You gotta fix that penguin bro!
                //..
                //..
                //Nope!
            }
            
            [bundle unload];
        }
    }
    
    if (oldBundles.count) {
        _oldNCBundles = oldBundles.copy;
    }
    
    if (newBundles.count) {
        _NCBundles = newBundles.copy;
    }
    
    if (IDs.count) {
        _NCBundleIDs = IDs.copy;
    }
}

- (void)loadBundles:(BOOL)alsoLoadReplacementBundles {
    [self loadNCBundles];
    
    NSMutableSet *bundles = [NSMutableSet set];
    
    NSMutableSet *bundleIDs = [NSMutableSet set];
    
    NSMutableDictionary *replacingBundles = (alsoLoadReplacementBundles ? [NSMutableDictionary dictionary] : nil);
    
    NSString *bundlePath = kCCSectionBundlePath;
    
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:bundlePath error:nil];
    
    NSSet *stockSections = (alsoLoadReplacementBundles ? kCCLoaderStockSections : nil);
    
    for (NSString *file in contents) {
        if ([file.pathExtension isEqualToString:@"bundle"]) {
            NSString *path = [bundlePath stringByAppendingPathComponent:file];
            
            NSBundle *bundle = [NSBundle bundleWithPath:path];
            
            Class principalClass = [bundle principalClass];
            
            if ([principalClass conformsToProtocol:@protocol(CCSection)]) {
                NSString *replaceID = [bundle objectForInfoDictionaryKey:kCCLoaderReplaceStockSectionInfoDicationaryKey];
                
                if (alsoLoadReplacementBundles && [stockSections containsObject:replaceID]) {
                    NSMutableArray *replacements = replacingBundles[replaceID];
                    
                    if (!replacements) {
                        replacements = [NSMutableArray array];
                    }
                    
                    [replacements addObject:bundle];
                    
                    replacingBundles[replaceID] = replacements;
                }
                else {
                    [bundleIDs addObject:bundle.bundleIdentifier];
                    [bundles addObject:bundle];
                }
            }
            
            [bundle unload];
        }
    }
    
    if (alsoLoadReplacementBundles && replacingBundles.count) {
        _replacingBundles = replacingBundles.copy;
    }
    
    if (bundles.count) {
        _bundleIDs = bundleIDs.copy;
        
        _bundles = bundles.copy;
    }
}

- (void)unloadBundles {
#if !ARC
    [_bundles release];
    [_bundleIDs release];
    [_replacingBundles release];
    [_oldNCBundles release];
    [_NCBundles release];
    [_NCBundleIDs release];
#endif
    
    _bundles = nil;
    _bundleIDs = nil;
    _replacingBundles = nil;
    _oldNCBundles = nil;
    _NCBundles = nil;
    _NCBundleIDs = nil;
}

- (void)dealloc {
#if !ARC
    [super dealloc];
#endif
    
    [self unloadBundles];
}

@end
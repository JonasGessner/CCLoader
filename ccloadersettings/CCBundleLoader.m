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


#define kCCLoaderStockCCDisplayNames @{@"com.apple.controlcenter.settings" : @"Settings", @"com.apple.controlcenter.brightness" : @"Brightness", @"com.apple.controlcenter.media-controls" : @"Media Controls", @"com.apple.controlcenter.air-stuff" : @"AirPlay/AirDrop", @"com.apple.controlcenter.quick-launch" : @"Quick Launch"}


#define kCCLoaderStockNCDisplayNames @{@"com.apple.attributionweeapp.bundle" : @"Attribution Widget", @"com.apple.CalendarWidget" : @"Calendar Widget", @"com.apple.reminders.todaywidget" : @"Reminders Widget", @"com.apple.stocksweeapp.bundle" : @"Stocks Widget"}


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

- (NSMutableDictionary *)loadNCBundles:(BOOL)names checkBundles:(BOOL)check {
    NSMutableDictionary *displayNames = (names ? [NSMutableDictionary dictionary] : nil);
    
    if (names) {
        [displayNames addEntriesFromDictionary:kCCLoaderStockNCDisplayNames];
    }
    
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
            
            NSDictionary *iOS7Info = [bundle objectForInfoDictionaryKey:@"SBUIWidgetViewControllers"];
            
            if (iOS7Info.count) {
                Class principalClass = (check ? [bundle classNamed:[iOS7Info.allValues lastObject]] : Nil);
                
                if (!check || [principalClass isSubclassOfClass:[_SBUIWidgetViewController class]]) {
                    NSString *ID = bundle.bundleIdentifier;
                    
                    if (ID) {
                        [IDs addObject:ID];
                        
                        if (names) {
                            NSString *displayName = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
                            
                            if (displayName && displayNames[ID] == nil) {
                                displayNames[ID] = displayName;
                            }
                        }
                        
                        [newBundles addObject:bundle];
                    }
                }
            }
            else {
                Class principalClass = (check ? [bundle principalClass] : Nil);
                
                if (!check || [principalClass conformsToProtocol:@protocol(BBWeeAppController)]) {
                    NSString *ID = bundle.bundleIdentifier;
                    
                    if (ID) {
                        [IDs addObject:ID];
                        
                        if (names) {
                            NSString *displayName = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
                            
                            if (displayName && displayNames[ID] == nil) {
                                displayNames[ID] = displayName;
                            }
                        }
                        
                        [oldBundles addObject:bundle];
                    }
                }
                else {
                    //You gotta fix that penguin bro!
                    //..
                    //..
                    //Nope!
                }
            }
            
            [bundle unload];
        }
    }
    
    for (NSString *file in contents2) {
        if ([file.pathExtension isEqualToString:@"bundle"]) {
            NSString *path = [bundlePath2 stringByAppendingPathComponent:file];
            
            NSBundle *bundle = [NSBundle bundleWithPath:path];
            
            NSDictionary *iOS7Info = [bundle objectForInfoDictionaryKey:@"SBUIWidgetViewControllers"];
            
            if (iOS7Info.count) {
                Class principalClass = (check ? [bundle classNamed:[iOS7Info.allValues lastObject]] : Nil);
                
                if (!check || [principalClass isSubclassOfClass:[_SBUIWidgetViewController class]]) {
                    NSString *ID = bundle.bundleIdentifier;
                    
                    if (ID) {
                        [IDs addObject:ID];
                        
                        if (names) {
                            NSString *displayName = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
                            
                            if (displayName && displayNames[ID] == nil) {
                                displayNames[ID] = displayName;
                            }
                        }
                        
                        [newBundles addObject:bundle];
                    }
                }
            }
            else {
                Class principalClass = (check ? [bundle principalClass] : Nil);
                
                if (!check || [principalClass conformsToProtocol:@protocol(BBWeeAppController)]) {
                    NSString *ID = bundle.bundleIdentifier;
                    
                    if (ID) {
                        [IDs addObject:ID];
                        
                        if (names) {
                            NSString *displayName = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
                            
                            if (displayName && displayNames[ID] == nil) {
                                displayNames[ID] = displayName;
                            }
                        }
                        
                        [oldBundles addObject:bundle];
                    }
                }
                else {
                    //You gotta fix that penguin bro!
                    //..
                    //..
                    //Nope!
                }
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
    
    return displayNames;
}

- (void)loadBundlesAndReplacements:(BOOL)alsoLoadReplacementBundles loadNames:(BOOL)names checkBundles:(BOOL)check {
    NSMutableDictionary *displayNames = [self loadNCBundles:names checkBundles:NO];
    
    if (names) {
        [displayNames addEntriesFromDictionary:kCCLoaderStockCCDisplayNames];
    }
    
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
            
            Class principalClass = (check ? [bundle principalClass] : Nil);
            
            if (!check || [principalClass conformsToProtocol:@protocol(CCSection)]) {
                NSString *replaceID = [bundle objectForInfoDictionaryKey:kCCLoaderReplaceStockSectionInfoDicationaryKey];
                
                if (alsoLoadReplacementBundles && [stockSections containsObject:replaceID]) {
                    NSMutableArray *replacements = replacingBundles[replaceID];
                    
                    if (!replacements) {
                        replacements = [NSMutableArray array];
                    }
                    
                    NSString *ID = bundle.bundleIdentifier;
                    
                    if (ID) {
                        if (names) {
                            NSString *displayName = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
                            
                            if (displayName && displayNames[ID] == nil) {
                                displayNames[ID] = displayName;
                            }
                        }
                        
                        [replacements addObject:bundle];
                        
                        replacingBundles[replaceID] = replacements;
                    }
                }
                else {
                    NSString *ID = bundle.bundleIdentifier;
                    if (ID) {
                        [bundleIDs addObject:ID];
                        
                        if (names) {
                            NSString *displayName = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
                            
                            if (displayName && displayNames[ID] == nil) {
                                displayNames[ID] = displayName;
                            }
                        }
                        
                        [bundles addObject:bundle];
                    }
                }
            }
            
            [bundle unload];
        }
    }
    
    if (alsoLoadReplacementBundles && replacingBundles.count) {
        _replacingBundles = replacingBundles.copy;
    }
    
    if (names && displayNames.count) {
        _displayNames = displayNames.copy;
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
    [_displayNames release];
#endif
    
    _bundles = nil;
    _bundleIDs = nil;
    _replacingBundles = nil;
    _oldNCBundles = nil;
    _NCBundles = nil;
    _NCBundleIDs = nil;
    _displayNames = nil;
}

- (void)dealloc {
#if !ARC
    [super dealloc];
#endif
    
    [self unloadBundles];
}

@end
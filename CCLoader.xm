//
//  CCLoader.xm
//  CCLoader
//
//  Created by Jonas Gessner on 04.01.2014.
//  Copyright (c) 2014 Jonas Gessner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#include <substrate.h>
#import <objc/runtime.h>

#import "CCLoaderSettings/CCBundleLoader.h"
#import "CCSectionViewController.h"
#import "CCScrollView.h"

#import "ControlCenter/SBControlCenterController.h"
#import "ControlCenter/SBControlCenterViewController.h"
#import "ControlCenter/SBControlCenterContainerView.h"
#import "ControlCenter/SBControlCenterContentContainerView.h"
#import "ControlCenter/SBControlCenterContentView.h"
#import "ControlCenter/SBControlCenterSeparatorView.h"

#import "SBMediaController.h"

#define kCCLoaderStockOrderedSections @[@"com.apple.controlcenter.settings", @"com.apple.controlcenter.brightness", @"com.apple.controlcenter.media-controls", @"com.apple.controlcenter.air-stuff", @"com.apple.controlcenter.quick-launch"]

#define kCCLoaderStockSections [NSSet setWithArray:kCCLoaderStockOrderedSections]

#define kCCLoaderSettingsPath [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"Preferences/de.j-gessner.ccloader.plist"]

#define iPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

static NSMutableDictionary *customSectionViewControllers = nil;

static NSMutableArray *sectionViewControllers = nil;
static NSMutableArray *strippedSectionViewControllers = nil;

static NSMutableArray *landscapeSectionViewControllers = nil;
static NSMutableArray *landscapeStrippedSectionViewControllers = nil;

static BOOL hideSeparators = NO;
static BOOL hideMediaControlsInCurrentSession = NO;

NS_INLINE NSMutableArray *sectionViewControllersForIDs(NSArray *IDs, SBControlCenterContentView *contentView, NSUInteger *mediaControlsIndex) {
    CCBundleLoader *loader = [CCBundleLoader sharedInstance];
    
    NSMutableArray *_sectionViewControllers = [NSMutableArray arrayWithCapacity:IDs.count];
    
    NSSet *stockLayout = kCCLoaderStockSections;
    
    NSMutableSet *bundles = loader.bundles.mutableCopy;
    
    if (!customSectionViewControllers) {
        customSectionViewControllers = [NSMutableDictionary dictionary];
    }
    
    NSMutableSet *usedCustomSections = [NSMutableSet setWithArray:customSectionViewControllers.allKeys];
    
    for (NSString *sectionID in IDs) {
        if ([stockLayout containsObject:sectionID]) {
            if ([sectionID isEqualToString:@"com.apple.controlcenter.settings"]) {
                [_sectionViewControllers addObject:contentView.settingsSection];
            }
            else if ([sectionID isEqualToString:@"com.apple.controlcenter.brightness"]) {
                [_sectionViewControllers addObject:contentView.brightnessSection];
            }
            else if ([sectionID isEqualToString:@"com.apple.controlcenter.media-controls"]) {
                if (mediaControlsIndex) {
                    *mediaControlsIndex = _sectionViewControllers.count;
                }
                
                [_sectionViewControllers addObject:contentView.mediaControlsSection];
            }
            else if ([sectionID isEqualToString:@"com.apple.controlcenter.air-stuff"]) {
                [_sectionViewControllers addObject:contentView.airplaySection];
            }
            else if ([sectionID isEqualToString:@"com.apple.controlcenter.quick-launch"]) {
                [_sectionViewControllers addObject:contentView.quickLaunchSection];
            }
            else {
                NSCAssert(0, @"Something has gone really wrong!");
            }
        }
        else {
            for (NSBundle *bundle in bundles) {
                if ([bundle.bundleIdentifier isEqualToString:sectionID]) {
                    CCSectionViewController *sectionViewController = customSectionViewControllers[sectionID];
                    
                    if (!sectionViewController) {
                        sectionViewController = [[%c(CCSectionViewController) alloc] initWithBundle:bundle];
                        customSectionViewControllers[sectionID] = sectionViewController;
                    }
                    
                    [usedCustomSections removeObject:sectionID];
                    
                    [_sectionViewControllers addObject:sectionViewController];
                    
                    [bundles removeObject:bundle];
                    break;
                }
            }
        }
    }
    
    for (NSString *unusedSection in usedCustomSections) {
        [customSectionViewControllers removeObjectForKey:unusedSection];
    }
    
    return _sectionViewControllers;
}

NS_INLINE void loadCCSections(SBControlCenterContentView *contentView) {
    NSCParameterAssert(contentView);
    
    strippedSectionViewControllers = nil;
    
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kCCLoaderSettingsPath];
    
    NSArray *sectionsToLoad = prefs[@"EnabledSections"];

    if (!sectionsToLoad) {
        sectionsToLoad = kCCLoaderStockOrderedSections;
    }
    
    NSMutableOrderedSet *landscapeSectionsToLoad = [NSMutableOrderedSet orderedSetWithArray:sectionsToLoad];
    
    [landscapeSectionsToLoad removeObject:@"com.apple.controlcenter.settings"];
    [landscapeSectionsToLoad removeObject:@"com.apple.controlcenter.quick-launch"];
    
    [landscapeSectionsToLoad insertObject:@"com.apple.controlcenter.settings" atIndex:0];
    [landscapeSectionsToLoad insertObject:@"com.apple.controlcenter.quick-launch" atIndex:landscapeSectionsToLoad.count];
    
    BOOL hideMediaControlsIfStopped = [prefs[@"HideMediaControls"] boolValue];
    hideSeparators = [prefs[@"HideSeparators"] boolValue];
    

    
    NSUInteger mediaControlsIndex = NSNotFound;
    NSUInteger landscapeMediaControlsIndex = NSNotFound;
    
    
    for (SBControlCenterSectionViewController *sectionViewController in landscapeSectionViewControllers) {
        [contentView _removeSectionController:sectionViewController];
    }
    
    sectionViewControllers = sectionViewControllersForIDs(sectionsToLoad, contentView, &mediaControlsIndex);
    
    landscapeSectionViewControllers = sectionViewControllersForIDs(landscapeSectionsToLoad.array, contentView, &landscapeMediaControlsIndex);
    
    if (hideMediaControlsIfStopped) {
        if (mediaControlsIndex != NSNotFound) {
            strippedSectionViewControllers = sectionViewControllers.mutableCopy;
            [strippedSectionViewControllers removeObjectAtIndex:mediaControlsIndex];
        }
        
        if (landscapeMediaControlsIndex != NSNotFound) {
            landscapeStrippedSectionViewControllers = landscapeSectionViewControllers.mutableCopy;
            [landscapeStrippedSectionViewControllers removeObjectAtIndex:landscapeMediaControlsIndex];
        }
    }
    
    NSMutableArray *separators = MSHookIvar<NSMutableArray *>(contentView, "_dividerViews");
    
    NSUInteger expectedCount = landscapeSectionViewControllers.count;
    
    if (expectedCount > 1 && !hideSeparators) {
        while (separators.count > expectedCount-1) {
            [[separators lastObject] removeFromSuperview];
            [separators removeLastObject];
        }
        
        while (separators.count < expectedCount-1) {
            SBControlCenterSeparatorView *separator = [[%c(SBControlCenterSeparatorView) alloc] initWithFrame:CGRectZero];
            
            [contentView addSubview:separator];
            
            [separators addObject:separator];
        }
    }
    else {
        for (UIView *v in separators) {
            [v removeFromSuperview];
        }
        
        [separators removeAllObjects];
    }
}

NS_INLINE void reloadCCSections(void) {
    SBControlCenterController *controller = [%c(SBControlCenterController) sharedInstanceIfExists];
    
    NSCParameterAssert(controller);
    
    
    SBControlCenterContentView *contentView = MSHookIvar<SBControlCenterContentView *>(MSHookIvar<SBControlCenterViewController *>(controller, "_viewController"), "_contentView");
    
    loadCCSections(contentView);
}


static BOOL landscape = NO;

static CGFloat realHeight = 0.0f;
static CGFloat fakeHeight = 0.0f;

static CCScrollView *_scroller = nil;

NS_INLINE UIScrollView *scroller(void) {
    if (!_scroller) {
        _scroller = [[CCScrollView alloc] init];
        _scroller.scrollsToTop = NO;
    }
    
    return _scroller;
}

#define kGrabberHeight 25.0f


%group main

%hook SBControlCenterContentContainerView

- (void)layoutSubviews {
    %orig;
    
    [UIView performWithoutAnimation:^{
        if (scroller().superview != self) {
            [self addSubview:scroller()];
        }
        
        CGRect frame = self.bounds;
        
        frame.origin.y = kGrabberHeight;
        frame.size.height = fakeHeight-kGrabberHeight;
        scroller().frame = frame;
        
        frame.size.height = realHeight-kGrabberHeight;
        scroller().contentSize = frame.size;
    }];
}

%end

%hook SBControlCenterSectionView

- (void)setFrame:(CGRect)frame {
    if (landscape && [self isKindOfClass:%c(SBCCButtonLayoutView)]) {
        frame.size.height = fakeHeight;
    }
    else {
        frame.origin.y -= kGrabberHeight;
    }
    
    %orig;
}

%end

%hook SBControlCenterSeparatorView

- (void)setFrame:(CGRect)frame {
    frame.origin.y -= kGrabberHeight;
    %orig;
}

%end

%hook SBControlCenterContentView

- (void)_removeSectionController:(SBControlCenterSectionViewController *)controller {
    %orig;
    [controller.view removeFromSuperview];
}

//- (NSArray *)subviews {
//    NSMutableArray *subviews = %orig.mutableCopy;
//    
//    [subviews removeObjectIdenticalTo:scroller()];
//    [subviews addObjectsFromArray:scroller().subviews];
//    
//    return subviews.copy;
//}

- (void)addSubview:(UIView *)subview {
    if ([subview isKindOfClass:%c(SBControlCenterSectionView)]) {
        if (landscape) {
            if ([subview isKindOfClass:%c(SBCCButtonLayoutView)]) {
                %orig;
            }
            else {
                [scroller() addSubview:subview];
            }
        }
        else {
            [scroller() addSubview:subview];
        }
    }
    else if ([subview isKindOfClass:%c(SBControlCenterSeparatorView)]) {
        [scroller() addSubview:subview];
    }
    else {
         %orig;
    }
}

- (void)setFrame:(CGRect)frame {
    frame.size.height = realHeight;
    
    %orig;
}

- (NSMutableArray *)_allSections {
    if (landscape) {
        if (hideMediaControlsInCurrentSession) {
            return landscapeStrippedSectionViewControllers;
        }
        else {
            return landscapeSectionViewControllers;
        }
    }
    else {
        if (hideMediaControlsInCurrentSession) {
            return strippedSectionViewControllers;
        }
        else {
            return sectionViewControllers;
        }
    }
}

%end


%hook SBControlCenterController

+ (id)_sharedInstanceCreatingIfNeeded:(BOOL)needed {
    SBControlCenterController *controller = %orig;
    
    if (controller && !sectionViewControllers) {
        SBControlCenterContentView *contentView = MSHookIvar<SBControlCenterContentView *>(MSHookIvar<SBControlCenterViewController *>(controller, "_viewController"), "_contentView");
        
        loadCCSections(contentView);
    }
    
    return controller;
}

%end


%hook SBControlCenterViewController

- (CGFloat)contentHeightForOrientation:(UIInterfaceOrientation)orientation {
    landscape = UIInterfaceOrientationIsLandscape(orientation);
    
	CGFloat height = %orig;
    
    if (landscape) {
		realHeight = kGrabberHeight;

        for (NSUInteger i = 1; i < landscapeSectionViewControllers.count-1; i++) {
            SBControlCenterSectionViewController *controller = landscapeSectionViewControllers[i];
            
            realHeight += [controller contentSizeForOrientation:orientation].height+1.5f;
			

        }
    } else
		realHeight = %orig;
    
    CGFloat screenHeight = self.view.frame.size.height;
    
    if (height > screenHeight) {
        height = screenHeight;
    }
    
    fakeHeight = height;
    
    return height;
}

- (void)controlCenterWillPresent {
    hideMediaControlsInCurrentSession = (strippedSectionViewControllers && ![[%c(SBMediaController) sharedInstance] nowPlayingApplication]);
    
    SBControlCenterContentView *contentView = MSHookIvar<SBControlCenterContentView *>(self, "_contentView");
    
    if (hideMediaControlsInCurrentSession) {
        [contentView _removeSectionController:contentView.mediaControlsSection];
    }
    
    [contentView _removeSectionController:contentView.settingsSection];
    [contentView _removeSectionController:contentView.quickLaunchSection];
    
    %orig;
}

- (void)controlCenterDidDismiss {
    %orig;
    
    [scroller() removeFromSuperview];
    
    realHeight = 0.0f;
    fakeHeight = 0.0f;
    
    landscape = NO;
}

%end

%end

%ctor {
	@autoreleasepool {
        CCBundleLoader *loader = [CCBundleLoader sharedInstance];
        [loader loadBundles];
        
		%init(main);
        
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadCCSections, CFSTR("de.j-gessner.ccloader.settingschanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	}
}

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

#import "ccloadersettings/CCBundleLoader.h"
#import "CCSectionViewController.h"
#import "CCScrollView.h"

#import "ControlCenter/SBControlCenterController.h"
#import "ControlCenter/SBControlCenterViewController.h"
#import "ControlCenter/SBControlCenterContainerView.h"
#import "ControlCenter/SBControlCenterContentContainerView.h"
#import "ControlCenter/SBControlCenterContentView.h"
#import "ControlCenter/SBControlCenterSeparatorView.h"

#define kCCLoaderStockOrderedSections @[@"com.apple.controlcenter.settings", @"com.apple.controlcenter.brightness", @"com.apple.controlcenter.media-controls", @"com.apple.controlcenter.air-stuff", @"com.apple.controlcenter.quick-launch"]

#define kCCLoaderStockSections [NSSet setWithArray:kCCLoaderStockOrderedSections]

#define kCCLoaderSettingsPath [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"Preferences/de.j-gessner.ccloader.plist"]

#define iPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

static NSMutableArray *sectionViewControllers = nil;

NS_INLINE void loadCCSections(SBControlCenterContentView *contentView) {
    NSCParameterAssert(contentView);
    
    CCBundleLoader *loader = [CCBundleLoader sharedInstance];
    
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kCCLoaderSettingsPath];
    
    NSArray *sectionsToLoad = prefs[@"EnabledSections"];
    
    if (!sectionsToLoad) {
        sectionsToLoad = kCCLoaderStockOrderedSections;
    }
    
    NSMutableArray *_sectionViewControllers = [NSMutableArray arrayWithCapacity:sectionsToLoad.count];
    
    NSSet *stockLayout = kCCLoaderStockSections;
    
    NSMutableSet *removeStockSections = [kCCLoaderStockSections mutableCopy];
    
    for (NSString *sectionID in sectionsToLoad) {
        BOOL reusedPreviousSection = NO;
        
        NSUInteger index = 0;
        
        for (CCSectionViewController *sectionViewController in sectionViewControllers) {
            if ([sectionViewController.sectionIdentifier isEqualToString:sectionID]) {
                [_sectionViewControllers addObject:sectionViewController];
                
                [sectionViewControllers removeObjectAtIndex:index];
                
                reusedPreviousSection = YES;
                
                break;
            }
            
            index++;
        }
        
        if (!reusedPreviousSection) {
            if ([stockLayout containsObject:sectionID]) {
                [removeStockSections removeObject:sectionID];
                
                if ([sectionID isEqualToString:@"com.apple.controlcenter.settings"]) {
                    [_sectionViewControllers addObject:contentView.settingsSection];
                }
                else if ([sectionID isEqualToString:@"com.apple.controlcenter.brightness"]) {
                    [_sectionViewControllers addObject:contentView.brightnessSection];
                }
                else if ([sectionID isEqualToString:@"com.apple.controlcenter.media-controls"]) {
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
                for (NSBundle *bundle in loader.bundles) {
                    if ([bundle.bundleIdentifier isEqualToString:sectionID]) {
                        CCSectionViewController *sectionViewController = [[%c(CCSectionViewController) alloc] initWithBundle:bundle];
                        
                        [_sectionViewControllers addObject:sectionViewController];
                        
                        break;
                    }
                }
            }
        }
    }
    
    for (CCSectionViewController *sectionViewController in sectionViewControllers) {
        [contentView _removeSectionController:sectionViewController];
    }
    
    sectionViewControllers = _sectionViewControllers;
    
    for (NSString *sectionID in removeStockSections) {
        if ([sectionID isEqualToString:@"com.apple.controlcenter.settings"]) {
            [contentView _removeSectionController:contentView.settingsSection];
        }
        else if ([sectionID isEqualToString:@"com.apple.controlcenter.brightness"]) {
            [contentView _removeSectionController:contentView.brightnessSection];
        }
        else if ([sectionID isEqualToString:@"com.apple.controlcenter.media-controls"]) {
            [contentView _removeSectionController:contentView.mediaControlsSection];
        }
        else if ([sectionID isEqualToString:@"com.apple.controlcenter.air-stuff"]) {
            [contentView _removeSectionController:contentView.airplaySection];
        }
        else if ([sectionID isEqualToString:@"com.apple.controlcenter.quick-launch"]) {
            [contentView _removeSectionController:contentView.quickLaunchSection];
        }
        else {
            NSCAssert(0, @"Something has gone really wrong!");
        }
    }
    
    
    
    NSMutableArray *separators = MSHookIvar<NSMutableArray *>(contentView, "_dividerViews");
    
    if (sectionViewControllers.count > 1) {
        while (separators.count > sectionViewControllers.count-1) {
            [[separators lastObject] removeFromSuperview];
            [separators removeLastObject];
        }
        
        while (separators.count < sectionViewControllers.count-1) {
            SBControlCenterSeparatorView *separator = [[%c(SBControlCenterSeparatorView) alloc] initWithFrame:CGRectZero];
            separator.alpha = 0.4f;
            
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

static CCScrollView *scroller = nil;


%group main

%hook SBControlCenterContentContainerView

- (void)layoutSubviews {
    if (iPad) {
        return %orig;
    }
    
    if (landscape) {
        if (scroller) {
            UIView *contentView = MSHookIvar<UIView *>(self, "_contentView");
            
            [self addSubview:contentView];
            
            [scroller removeFromSuperview];
            scroller = nil;
        }
        
        return %orig;
    }
    
    %orig;
    
    if (!scroller) {
        scroller = [[CCScrollView alloc] init];
        scroller.scrollsToTop = NO;
    }
    
    if (scroller.superview != self) {
        [self addSubview:scroller];
    }
    
    UIView *contentView = MSHookIvar<UIView *>(self, "_contentView");
    
    if (contentView.superview != scroller) {
        [scroller addSubview:contentView];
    }
    
    CGRect frame = self.bounds;
    
    frame.size.height = fakeHeight;
    scroller.frame = frame;
    
    frame.size.height = realHeight;
    scroller.contentSize = frame.size;
}

%end


%hook SBControlCenterContentView

- (void)setFrame:(CGRect)frame {
    if (landscape || iPad) {
        return %orig;
    }
    
    frame.size.height = realHeight;
    
    %orig;
}

- (NSMutableArray *)_allSections {
    if (landscape || iPad) {
        return %orig;
    }
    else {
        return sectionViewControllers;
    }
}

%end

%hook SBControlCenterViewController

- (CGFloat)contentHeightForOrientation:(UIInterfaceOrientation)orientation {
    if (iPad) {
        return %orig;
    }
    
    landscape = UIInterfaceOrientationIsLandscape(orientation);
    
    CGFloat height = %orig;
    
    if (landscape) {
        return height;
    }
    
    realHeight = height;
    
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    if (height > screenHeight) {
        height = screenHeight;
        fakeHeight = screenHeight;
    }
    else {
        fakeHeight = height;
    }
    
    return height;
}

- (void)_handlePan:(UIPanGestureRecognizer *)gesture {
    if (landscape || iPad) {
        return %orig;
    }
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [scroller setContentOffset:CGPointZero];
    }
    
    %orig;
}

- (void)controlCenterWillPresent {
    if (iPad) {
        return %orig;
    }
    
    if (!sectionViewControllers) {
        loadCCSections(MSHookIvar<SBControlCenterContentView *>(self, "_contentView"));
    }
    
    %orig;
}

- (void)controlCenterDidDismiss {
    if (iPad) {
        return %orig;
    }
    
    %orig;
    
    [scroller removeFromSuperview];
    
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

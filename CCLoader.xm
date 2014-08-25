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

#import "CCLoaderSettings/CCSection-Protocol.h"
#import "CCLoaderSettings/BBWeeAppController-Protocol.h"
#import "CCLoaderSettings/SpringBoardUIServices/_SBUIWidgetViewController.h"

#import "CCLoaderSettings/CCBundleLoader.h"
#import "CCSectionViewController.h"
#import "CCScrollView.h"

#import "ControlCenter/SBControlCenterController.h"
#import "ControlCenter/SBControlCenterViewController.h"
#import "ControlCenter/SBControlCenterContainerView.h"
#import "ControlCenter/SBControlCenterContentContainerView.h"
#import "ControlCenter/SBControlCenterContentView.h"
#import "ControlCenter/SBControlCenterSeparatorView.h"
#import "ControlCenter/SBCCAirStuffSectionController.h"

#import "SBMediaController.h"

#define kCCLoaderSettingsPath [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"Preferences/de.j-gessner.ccloader.plist"]

#define iPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#define kCCGrabberHeight 25.0f
#define kCCSeparatorHeight 1.5f

static NSMutableDictionary *customSectionViewControllers = nil;

static NSMutableArray *sectionViewControllers = nil;
static NSMutableArray *landscapeSectionViewControllers = nil;

static BOOL hideMediaControlsInCurrentSession = NO;

static UIInterfaceOrientation currentOrientation = UIInterfaceOrientationPortrait;

#define kCCIsInLandscape UIInterfaceOrientationIsLandscape(currentOrientation)

static BOOL contentHeightIsSet = NO;
static CGFloat contentHeight = 0.0f;
static CGFloat realContentHeight = 0.0f;

static BOOL loadedSections = NO;

static NSMutableArray *separators = nil;


static BOOL hideMediaControlsIfStopped = NO;
static BOOL hideSeparators = NO;
static BOOL visible = NO;

static CCScrollView *_scrollView = nil;

NS_INLINE UIScrollView *scrollView(void) {
    if (!_scrollView) {
        _scrollView = [[CCScrollView alloc] init];
        _scrollView.scrollsToTop = NO;
    }
    
    return _scrollView;
}

#pragma mark - Helper Functions

NS_INLINE SBControlCenterSectionViewController *stockSectionViewControllerForID(SBControlCenterContentView *contentView, NSString *sectionID) {
    if ([sectionID isEqualToString:@"com.apple.controlcenter.settings"]) {
        return (SBControlCenterSectionViewController *)contentView.settingsSection;
    }
    else if ([sectionID isEqualToString:@"com.apple.controlcenter.brightness"]) {
        return (SBControlCenterSectionViewController *)contentView.brightnessSection;
    }
    else if ([sectionID isEqualToString:@"com.apple.controlcenter.media-controls"]) {
        return (SBControlCenterSectionViewController *)contentView.mediaControlsSection;
    }
    else if ([sectionID isEqualToString:@"com.apple.controlcenter.air-stuff"]) {
        return (SBControlCenterSectionViewController *)contentView.airplaySection;
    }
    else if ([sectionID isEqualToString:@"com.apple.controlcenter.quick-launch"]) {
        return (SBControlCenterSectionViewController *)contentView.quickLaunchSection;
    }
    else {
        return nil;
    }
}

/*NS_INLINE void setStockSectionViewControllerForID(SBControlCenterContentView *contentView, NSString *sectionID, id value) {
    if ([sectionID isEqualToString:@"com.apple.controlcenter.settings"]) {
        contentView.settingsSection = value;
    }
    else if ([sectionID isEqualToString:@"com.apple.controlcenter.brightness"]) {
        contentView.brightnessSection = value;
    }
    else if ([sectionID isEqualToString:@"com.apple.controlcenter.media-controls"]) {
        contentView.mediaControlsSection = value;
    }
    else if ([sectionID isEqualToString:@"com.apple.controlcenter.air-stuff"]) {
        contentView.airplaySection = value;
    }
    else if ([sectionID isEqualToString:@"com.apple.controlcenter.quick-launch"]) {
        contentView.quickLaunchSection = value;
    }
}*/

NS_INLINE BOOL checkBundleForType(NSBundle *bundle, CCBundleType type) {
    if (type == CCBundleTypeDefault) {
        Class principalClass = [bundle principalClass];
        
        return [principalClass conformsToProtocol:@protocol(CCSection)];
    }
    else if (type == CCBundleTypeBBWeeApp) {
        Class principalClass = [bundle principalClass];
        
        return [principalClass conformsToProtocol:@protocol(BBWeeAppController)];
    }
    else if (type == CCBundleTypeWeeApp) {
        NSDictionary *iOS7Info = [bundle objectForInfoDictionaryKey:@"SBUIWidgetViewControllers"];
        
        Class principalClass = [bundle classNamed:[iOS7Info.allValues lastObject]];
        
        return [principalClass isSubclassOfClass:[_SBUIWidgetViewController class]];
    }
    
    return NO;
}

NS_INLINE NSMutableArray *sectionViewControllersForIDs(NSArray *IDs, NSDictionary *replacements, SBControlCenterViewController *viewController, SBControlCenterContentView *contentView, NSUInteger *mediaControlsIndex, BOOL cleanUnusedSections) {
    CCBundleLoader *loader = [CCBundleLoader sharedInstance];
    
    NSMutableArray *_sectionViewControllers = [[NSMutableArray alloc] initWithCapacity:IDs.count];
    
    NSSet *stockLayout = kCCLoaderStockSections;
    
    NSMutableSet *bundles = loader.bundles.mutableCopy;
    
    NSMutableSet *NCBundles = loader.NCBundles.mutableCopy;
    
    NSMutableSet *oldNCBundles = loader.oldNCBundles.mutableCopy;
    
    NSDictionary *replacingBundles = loader.replacingBundles;
    
    if (!customSectionViewControllers) {
        customSectionViewControllers = [[NSMutableDictionary alloc] init];
    }
    
    NSMutableSet *usedCustomSections = (cleanUnusedSections ? [NSMutableSet setWithArray:customSectionViewControllers.allKeys] : nil);
    
    CCSectionViewController *(^loadCustomSection)(NSString *sectionIdentifier, NSBundle *loadingBundle, CCBundleType type, BOOL *fallbackToStockSection) = ^CCSectionViewController *(NSString *sectionIdentifier, NSBundle *loadingBundle, CCBundleType type, BOOL *fallbackToStockSection) {
        if (!checkBundleForType(loadingBundle, type)) {
            [loadingBundle unload];
            NSLog(@"[CCLoader] ERROR: Bundle %@ is invalid", loadingBundle);
            return nil;
        }
        else {
            CCSectionViewController *sectionViewController = customSectionViewControllers[sectionIdentifier];
            
            Class principalClass = loadingBundle.principalClass;
            
            BOOL available = !(type == CCBundleTypeDefault && [principalClass respondsToSelector:@selector(isUnavailable)] && [principalClass isUnavailable]);
                        
            if (!sectionViewController && available) {
                sectionViewController = [[%c(CCSectionViewController) alloc] initWithCCLoaderBundle:loadingBundle type:type];
                
                [sectionViewController setDelegate:viewController];
                
                customSectionViewControllers[sectionIdentifier] = sectionViewController;
                
                [sectionViewController release];
            }
            else if (sectionViewController && !available) {
            	[customSectionViewControllers removeObjectForKey:sectionIdentifier];
                sectionViewController = nil;
            }
            
            if (cleanUnusedSections) {
                [usedCustomSections removeObject:sectionIdentifier];
            }
            
            if (!sectionViewController) {
                if (fallbackToStockSection) {
                    *fallbackToStockSection = YES;
                }
            }
            else {
                [_sectionViewControllers addObject:sectionViewController];
            }
            
            [bundles removeObject:loadingBundle];
            
            return sectionViewController;
        }
    };
    
    for (NSString *sectionID in IDs) {
        if ([stockLayout containsObject:sectionID]) {
            if ([sectionID isEqualToString:@"com.apple.controlcenter.media-controls"]) {
                if (mediaControlsIndex) {
                    *mediaControlsIndex = _sectionViewControllers.count;
                }
            }
            
            NSBundle *replacingBundle = nil;
            
            
            NSString *replacingID = replacements[sectionID];
            
            if ([replacingID isEqualToString:@"de.j-gessner.ccloader.reserved.defaultStockSection"]) {
                [_sectionViewControllers addObject:stockSectionViewControllerForID(contentView, sectionID)];
            }
            else {
                if (replacingID) {
                    for (NSBundle *bundle in replacingBundles[sectionID]) {
                        if ([bundle.bundleIdentifier isEqualToString:replacingID]) {
                            replacingBundle = bundle;
                            break;
                        }
                    }
                }
                
                if (replacingBundle) {
                    BOOL useStockSection = NO;
                    
                    CCSectionViewController *section = loadCustomSection(replacingID, replacingBundle, CCBundleTypeDefault, &useStockSection);
                    
                    if (useStockSection) {
                        [_sectionViewControllers addObject:stockSectionViewControllerForID(contentView, sectionID)];
                    }
                    else {
                        [section _CCLoader_setReplacingSectionViewController:stockSectionViewControllerForID(contentView, sectionID)];
                    }
                }
                else {
                    [_sectionViewControllers addObject:stockSectionViewControllerForID(contentView, sectionID)];
                }
            }
        }
        else {
            BOOL added = NO;
            
            for (NSBundle *bundle in bundles) {
                if ([bundle.bundleIdentifier isEqualToString:sectionID]) {
                    loadCustomSection(sectionID, bundle, CCBundleTypeDefault, NULL);
                    added = YES;
                    break;
                }
            }
            
            if (!added) {
                for (NSBundle *bundle in NCBundles) {
                    if ([bundle.bundleIdentifier isEqualToString:sectionID]) {
                        loadCustomSection(sectionID, bundle, CCBundleTypeWeeApp, NULL);
                        added = YES;
                        break;
                    }
                }
                
                if (!added) {
                    for (NSBundle *bundle in oldNCBundles) {
                        if ([bundle.bundleIdentifier isEqualToString:sectionID]) {
                            loadCustomSection(sectionID, bundle, CCBundleTypeBBWeeApp, NULL);
                            added = YES;
                            break;
                        }
                    }
                }
            }
        }
    }
    
    [bundles release];
    [NCBundles release];
    [oldNCBundles release];
    
    if (cleanUnusedSections) {
        for (NSString *unusedSection in usedCustomSections) {
            [customSectionViewControllers removeObjectForKey:unusedSection];
        }
    }
    
    if (!customSectionViewControllers.count) {
        [customSectionViewControllers release];
        customSectionViewControllers = nil;
    }
    
    return _sectionViewControllers;
}

NS_INLINE void loadCCSections(SBControlCenterViewController *viewController, SBControlCenterContentView *contentView) {
    NSCParameterAssert(contentView);
    NSCParameterAssert(viewController);
    
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kCCLoaderSettingsPath];
    
    NSArray *sectionsToLoad = (iPad ? kCCLoaderStockOrderedSections : prefs[@"EnabledSections"]);
    
    NSDictionary *replacements = prefs[@"ReplacingBundles"];
    
    if (!sectionsToLoad) {
        sectionsToLoad = kCCLoaderStockOrderedSections;
    }
    
    NSMutableOrderedSet *landscapeSectionsToLoad = [NSMutableOrderedSet orderedSetWithArray:sectionsToLoad];
    
    [landscapeSectionsToLoad removeObject:@"com.apple.controlcenter.settings"];
    [landscapeSectionsToLoad removeObject:@"com.apple.controlcenter.quick-launch"];
    
    [landscapeSectionsToLoad insertObject:@"com.apple.controlcenter.settings" atIndex:0];
    [landscapeSectionsToLoad insertObject:@"com.apple.controlcenter.quick-launch" atIndex:landscapeSectionsToLoad.count];
    
    hideMediaControlsIfStopped = [prefs[@"HideMediaControls"] boolValue];
    hideSeparators = [prefs[@"HideSeparators"] boolValue];
    
    //Remove current section view controllers
    for (SBControlCenterSectionViewController *sectionViewController in landscapeSectionViewControllers) {
        [contentView _removeSectionController:sectionViewController];
    }
    
    [sectionViewControllers release];
    sectionViewControllers = nil;
    
    [landscapeSectionViewControllers release];
    landscapeSectionViewControllers = nil;
    
    sectionViewControllers = sectionViewControllersForIDs(sectionsToLoad, replacements, viewController, contentView, 0, NO);
    
    landscapeSectionViewControllers = sectionViewControllersForIDs(landscapeSectionsToLoad.array, replacements, viewController, contentView, 0, YES);
}

NS_INLINE void reloadCCSections(void) {
    SBControlCenterController *controller = [%c(SBControlCenterController) sharedInstanceIfExists];
    
    NSCParameterAssert(controller);
    
    SBControlCenterViewController *viewController = MSHookIvar<SBControlCenterViewController *>(controller, "_viewController");
    
    SBControlCenterContentView *contentView = MSHookIvar<SBControlCenterContentView *>(viewController, "_contentView");
    
    loadCCSections(viewController, contentView);
}


#define TIME_MEASURE_START(i) CFTimeInterval start##i = CFAbsoluteTimeGetCurrent()
#define TIME_MEASURE_END(i) NSLog(@"ELAPSED TIME (%i) %f", i, CFAbsoluteTimeGetCurrent()-start##i)

#pragma mark - Swizzles


%group main



%hook SBControlCenterContentView

- (void)layoutSubviews {
    if (iPad) {
        return %orig;
    }
    
    if (scrollView().superview != self) {
        [self addSubview:scrollView()];
    }
    
    NSMutableArray *_separators = MSHookIvar<NSMutableArray *>(self, "_dividerViews");
    
    if (_separators) {
        for (SBControlCenterSeparatorView *separator in _separators) {
            [separator removeFromSuperview];
        }
        
        [_separators removeAllObjects];
        
        MSHookIvar<NSMutableArray *>(self, "_dividerViews") = nil;
    }
    
    %orig;
    
    CGRect frame = self.bounds;
    
    if (!CGRectIsEmpty(frame)) {
        frame.origin.y = kCCGrabberHeight;
        frame.size.height = contentHeight-kCCGrabberHeight;
        scrollView().frame = frame;
        
        frame.size.height = realContentHeight-kCCGrabberHeight;
        scrollView().contentSize = frame.size;
        
        
        NSUInteger index = 0;
        
        NSMutableArray *sections = self._allSections;
        
        UIViewController *previous = nil;
        
        NSUInteger separatorCount = 0;
        
        BOOL landscape = kCCIsInLandscape;
        
        while (index < sections.count) {
            SBControlCenterSectionViewController *viewController = sections[index];
            
            UIView *view = viewController.view;
            
            if (!view.hidden && [viewController enabledForOrientation:currentOrientation]) {
                CGRect frame = view.frame;
                
                BOOL landscapeSideSection = (kCCIsInLandscape && (index == 0 || index == sections.count-1));
                
                if (landscapeSideSection) {
                    frame.size.height = contentHeight;
                }
                else {
                    if (view.superview != scrollView()) {
                        [scrollView() addSubview:view];
                    }
                    
                    frame.origin.y = CGRectGetMaxY(previous.view.frame)+kCCSeparatorHeight;
                    frame.size.height = [viewController contentSizeForOrientation:currentOrientation].height;
                }
                
                view.frame = frame;
                
                
                
                if (!landscapeSideSection && index < sections.count-1-landscape && !CGRectIsEmpty(frame)) {
                    if (!separators) {
                        separators = [[NSMutableArray alloc] init];
                    }
                    
                    SBControlCenterSeparatorView *separator = (separators.count > separatorCount ? separators[separatorCount] : nil);
                    
                    if (!separator) {
                        separator = [[%c(SBControlCenterSeparatorView) alloc] initWithFrame:CGRectZero];
                        
                        [scrollView() addSubview:separator];
                        
                        [separators addObject:separator];
                        
                        [separator release];
                    }
                    
                    
                    if (separator.superview != scrollView()) {
                        [scrollView() addSubview:separator];
                    }
                    
                    separator.hidden = hideSeparators;
                    
                    CGRect separatorFrame = CGRectZero;
                    
                    separatorFrame.origin.x = view.frame.origin.x;
                    separatorFrame.origin.y = CGRectGetMaxY(view.frame);
                    
                    separatorFrame.size.width = view.frame.size.width;
                    separatorFrame.size.height = kCCSeparatorHeight;
                    
                    
                    separator.frame = separatorFrame;
                    
                    separatorCount++;
                }
                
                if (!landscapeSideSection) {
                    previous = viewController;
                }
            }
            
            index++;
        }
        
        while (separators.count > separatorCount) {
            SBControlCenterSeparatorView *separator = separators.lastObject;
            
            [separator removeFromSuperview];
            
            [separators removeLastObject];
        }
    }
}

- (void)_removeSectionController:(SBControlCenterSectionViewController *)controller {
    if (iPad) {
        return %orig;
    }
    
    %orig;
    
    [controller willMoveToParentViewController:nil];
    [controller.view removeFromSuperview];
    [controller removeFromParentViewController];
}

- (void)setFrame:(CGRect)frame {
    if (iPad) {
        return %orig;
    }
    
    frame.size.height = realContentHeight;
    
    %orig;
}

- (NSMutableArray *)_allSections {
    NSMutableArray *toBeReturned = nil;
    
    if (kCCIsInLandscape) {
        toBeReturned = landscapeSectionViewControllers;
    }
    else {
        toBeReturned = sectionViewControllers;
    }
    
    for (SBControlCenterSectionViewController *vc in toBeReturned) {
        if (![vc enabledForOrientation:currentOrientation]) {
            vc.view.hidden = YES;
        }
        else if (vc == self.mediaControlsSection && hideMediaControlsInCurrentSession) {
            vc.view.hidden = YES;
        }
        else {
            vc.view.hidden = NO;
        }
    }
    
    return toBeReturned;
}

%end

%hook SBControlCenterController

+ (id)_sharedInstanceCreatingIfNeeded:(BOOL)needed {
    SBControlCenterController *controller = %orig;
    
    if (controller && !loadedSections) {
        loadedSections = YES;
        
        SBControlCenterViewController *viewController = MSHookIvar<SBControlCenterViewController *>(controller, "_viewController");
        
        SBControlCenterContentView *contentView = MSHookIvar<SBControlCenterContentView *>(viewController, "_contentView");
        
        loadCCSections(viewController, contentView);
    }
    
    return controller;
}


- (void)dealloc {
    [_scrollView removeFromSuperview];
    [_scrollView release];
    _scrollView = nil;
    
    realContentHeight = 0.0f;
    contentHeight = 0.0f;
    
    contentHeightIsSet = NO;
    
    hideMediaControlsInCurrentSession = NO;
    
    for (SBControlCenterSeparatorView *separator in separators) {
        [separator removeFromSuperview];
    }
    
    [separators removeAllObjects];
    
    separators = nil;
    
    [customSectionViewControllers release];
    customSectionViewControllers = nil;
    
    [sectionViewControllers release];
    sectionViewControllers = nil;
    
    [landscapeSectionViewControllers release];
    landscapeSectionViewControllers = nil;
    
    loadedSections = NO;
    
    %orig;
}

%end


%hook SBControlCenterViewController

- (CGFloat)contentHeightForOrientation:(UIInterfaceOrientation)orientation {
    currentOrientation = orientation;
    
    if (iPad) {
        return %orig;
    }
    
    if (!contentHeightIsSet) {
        if (kCCIsInLandscape) {
            contentHeight = %orig;
            
            realContentHeight = kCCGrabberHeight;
            
            SBControlCenterContentView *contentView = MSHookIvar<SBControlCenterContentView *>(self, "_contentView");
            
            NSMutableArray *search = contentView._allSections;
            
            NSUInteger i = 1;
            
            while (i < search.count-1) {
                SBControlCenterSectionViewController *controller = search[i];
                
                if (!controller.view.hidden && [controller enabledForOrientation:currentOrientation]) {
                    realContentHeight += [controller contentSizeForOrientation:orientation].height+(i > 1 ? kCCSeparatorHeight : 0.0f);
                }
                
                i++;
            }
            
            if (realContentHeight < contentHeight) {
                realContentHeight = contentHeight;
            }
        }
        else {
            realContentHeight = kCCGrabberHeight;
            
            SBControlCenterContentView *contentView = MSHookIvar<SBControlCenterContentView *>(self, "_contentView");
            
            NSMutableArray *search = contentView._allSections;
            
            NSUInteger i = 0;
            
            while (i < search.count) {
                SBControlCenterSectionViewController *controller = search[i];
                
                if (!controller.view.hidden && [controller enabledForOrientation:currentOrientation]) {
                    realContentHeight += [controller contentSizeForOrientation:orientation].height+(i >= 1 ? kCCSeparatorHeight : 0.0f);
                }
                
                i++;
            }
            
            CGFloat screenHeight = self.view.frame.size.height;
            
            if (realContentHeight > screenHeight) {
                contentHeight = screenHeight;
            }
            else {
                contentHeight = realContentHeight;
            }
        }
        
        contentHeightIsSet = YES;
    }
    
    return contentHeight;
}

- (void)noteSectionEnabledStateDidChange:(SBControlCenterSectionViewController *)section {
    if (iPad) {
        return %orig;
    }
    
    if (self.view.window) {
        [UIView animateWithDuration:0.2 delay:0.0 options:(UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState) animations:^{
            [self _CCLoader_updateContentFrame];
        } completion:nil];
    }
    
    %orig;
}

%new
- (void)_CCLoader_updateContentFrame {
    void (^orig)(void) = ^{
        if ([self respondsToSelector:@selector(_updateContentFrame)]) {
            [self _updateContentFrame];
        }
        else {
            SBControlCenterContainerView *containerView = MSHookIvar<SBControlCenterContainerView *>(self, "_containerView");
            [containerView _updateContentFrame];
        }
    };
    
    if (iPad) {
        return orig();
    }
    
    contentHeightIsSet = NO;
    
    orig();
    
    SBControlCenterContentView *contentView = MSHookIvar<SBControlCenterContentView *>(self, "_contentView");
    
    [contentView setNeedsLayout];
}

%new
- (void)_CCLoader_reloadContentHeight {
    SBControlCenterContentView *contentView = MSHookIvar<SBControlCenterContentView *>(self, "_contentView");
    
    [contentView setNeedsLayout];
    [contentView layoutIfNeeded];
    
    [UIView animateWithDuration:0.2 delay:0.0 options:(UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState) animations:^{
        [self _CCLoader_updateContentFrame];
    } completion:nil];
}

- (void)controlCenterWillBeginTransition {
    if (visible) {
        //        visible = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CCLoaderCCWillDisappearNotification" object:nil];
    }
    
    %orig;
}

- (void)controlCenterDidFinishTransition {
    %orig;
    
    BOOL open = self.presented;
    
    if (open && !visible) {
        visible = YES;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CCLoaderCCDidAppearNotification" object:nil];
    }
}

- (void)controlCenterWillPresent {
    hideMediaControlsInCurrentSession = (hideMediaControlsIfStopped && ![[%c(SBMediaController) sharedInstance] nowPlayingApplication]);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_CCLoader_reloadContentHeight) name:@"CCLoaderReloadControlCenterHeight" object:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CCLoaderCCWillAppearNotification" object:nil];
    
    SBControlCenterContentView *contentView = MSHookIvar<SBControlCenterContentView *>(self, "_contentView");
    
    if (hideMediaControlsInCurrentSession) {
        [contentView _removeSectionController:contentView.mediaControlsSection];
    }
    
    %orig;
}

- (void)controlCenterDidDismiss {
    %orig;
    
    if (kCCIsInLandscape) {
        SBControlCenterContentView *contentView = MSHookIvar<SBControlCenterContentView *>(self, "_contentView");
        
        [contentView _removeSectionController:contentView.settingsSection];
        [contentView _removeSectionController:contentView.quickLaunchSection];
    }
    
    _scrollView.contentOffset = CGPointZero;
    
    contentHeight = 0.0f;
    realContentHeight = 0.0f;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CCLoaderCCDidDisappearNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CCLoaderReloadControlCenterHeight" object:nil];
    
    contentHeightIsSet = NO;
    
    visible = NO;
}

%end

%end

#pragma mark - Constructor

%ctor {
	@autoreleasepool {
        CCBundleLoader *loader = [CCBundleLoader sharedInstance];
        
        [loader loadBundlesAndReplacements:YES loadNames:NO checkBundles:NO];
        
        NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:kCCLoaderSettingsPath];
        
        if (!prefs) {
            prefs = [NSMutableDictionary dictionary];
        }
        
        NSMutableArray *enabledSections = [prefs[@"EnabledSections"] mutableCopy];
        
        if (!enabledSections) {
            enabledSections = kCCLoaderStockOrderedSections.mutableCopy;
        }
        
        NSMutableArray *disabledSections = [prefs[@"DisabledSections"] mutableCopy];
        
        if (!disabledSections) {
            disabledSections = [[NSMutableArray alloc] init];
        }
        
        NSMutableOrderedSet *allIDs = [NSMutableOrderedSet orderedSetWithSet:loader.bundleIDs];
        
        if (!allIDs) {
            allIDs = [NSMutableOrderedSet orderedSet];
        }
        
        [allIDs addObjectsFromArray:loader.NCBundleIDs.allObjects];
        
        [allIDs addObjectsFromArray:kCCLoaderStockOrderedSections];
        
        //Remove deleted bundles
        NSUInteger i = 0;
        
        while (enabledSections.count > 0 && i < enabledSections.count) {
            NSString *ID = enabledSections[i];
            
            if (![allIDs containsObject:ID]) {
                [enabledSections removeObjectAtIndex:i];
            }
            else {
                i++;
            }
        }
        
        i = 0;
        
        while (disabledSections.count > 0 && i < disabledSections.count) {
            NSString *ID = disabledSections[i];
            
            if (![allIDs containsObject:ID]) {
                [disabledSections removeObjectAtIndex:i];
            }
            else {
                i++;
            }
        }
        
        //Add new bundles
        [allIDs minusSet:[NSSet setWithArray:enabledSections]];
        [allIDs minusSet:[NSSet setWithArray:disabledSections]];
        
        NSSet *immutableAllIds = allIDs.copy;
        
        //Add new NC bundles to disabled sections
        for (NSString *remaining in immutableAllIds) {
            if ([loader.NCBundleIDs containsObject:remaining]) {
                [disabledSections addObject:remaining];
                
                [allIDs removeObject:remaining];
            }
        }
        
        [immutableAllIds release];
        
        [enabledSections addObjectsFromArray:allIDs.array];
        
        if (enabledSections) {
            prefs[@"EnabledSections"] = enabledSections;
        }
        else {
            [prefs removeObjectForKey:@"EnabledSections"];
        }
        
        if (disabledSections) {
            prefs[@"DisabledSections"] = disabledSections;
        }
        else {
            [prefs removeObjectForKey:@"DisabledSections"];
        }
        
        
        NSMutableDictionary *replacing = loader.replacingBundles.mutableCopy;
        
        if (!replacing.count) {
            [prefs removeObjectForKey:@"ReplacingBundles"];
        }
        else {
            NSMutableDictionary *replacements = [prefs[@"ReplacingBundles"] mutableCopy];
            
            if (!replacements) {
                replacements = [[NSMutableDictionary alloc] init];
            }
            
            for (NSString *key in [replacements.copy autorelease]) {
                NSString *setReplacementID = replacements[key];
                
                NSArray *replacementBundles = replacing[key];
                
                if (replacementBundles) {
                    if (![setReplacementID isEqualToString:@"de.j-gessner.ccloader.reserved.defaultStockSection"]) {
                        BOOL found = NO;
                        
                        for (NSBundle *bundle in replacementBundles) {
                            if ([bundle.bundleIdentifier isEqualToString:setReplacementID]) {
                                found = YES;
                                break;
                            }
                        }
                        
                        if (!found) {
                            replacements[key] = [replacementBundles.firstObject bundleIdentifier];
                        }
                    }
                    
                    [replacing removeObjectForKey:key];
                }
                else {
                    [replacements removeObjectForKey:key];
                }
            }
            
            for (NSString *key in replacing) {
                NSArray *replacementBundles = replacing[key];
                
                replacements[key] = [replacementBundles.firstObject bundleIdentifier];
            }
            
            prefs[@"ReplacingBundles"] = replacements;
            
            [replacements release];
        }
        
        
        [prefs writeToFile:kCCLoaderSettingsPath atomically:YES];
        
        [replacing release];
        [enabledSections release];
        [disabledSections release];
        
        
        %init(main);
        
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadCCSections, CFSTR("de.j-gessner.ccloader.settingschanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	}
}

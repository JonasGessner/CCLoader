//
//  CCSectionViewController.xm
//  CCLoader
//
//  Created by Jonas Gessner on 04.01.2014.
//  Copyright (c) 2014 Jonas Gessner. All rights reserved.
//

#import "CCSectionViewController.h"
#import "CCSectionView.h"

#import "ControlCenter/SBControlCenterController.h"
#import "ControlCenter/SBControlCenterViewController.h"

#import "CCLoaderSettings/SpringBoardUIServices/_SBUIWidgetViewController.h"

#import "CCLoaderSettings/BBWeeAppController-Protocol.h"

#import <objc/runtime.h>

#include <substrate.h>

#define iPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#define selfView ((CCSectionView *)self.view)

#define selfSection self._CCLoader_section

#define selfBundleType self._CCLoader_bundleType

@interface CCSectionViewController ()

- (void)_CCLoader_setBundle:(NSBundle *)bundle;

- (void)_CCLoader_setSection:(_SBUIWidgetViewController <CCSection, BBWeeAppController> *)section;
- (_SBUIWidgetViewController <CCSection, BBWeeAppController> *)_CCLoader_section;

- (CCBundleType)_CCLoader_bundleType;

@end

%subclass CCSectionViewController : SBControlCenterSectionViewController <CCSectionDelegate, _SBUIWidgetHost>

%new
- (id)initWithCCLoaderBundle:(NSBundle *)bundle type:(CCBundleType)type {
    self = [self init];
    if (self) {
        objc_setAssociatedObject(self, @selector(bundleType), @(type), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_CCLoader_controlCenterWillAppear) name:@"CCWillAppearNotification" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_CCLoader_controlCenterDidAppear) name:@"CCDidAppearNotification" object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_CCLoader_controlCenterWillDisappear) name:@"CCWillDisappearNotification" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_CCLoader_controlCenterDidDisappear) name:@"CCDidDisappearNotification" object:nil];
        
        [self _CCLoader_setBundle:bundle];
        
        
        Class principalClass = Nil;
        
        if (type == CCBundleTypeWeeApp) {
            principalClass = [bundle classNamed:[[[bundle objectForInfoDictionaryKey:@"SBUIWidgetViewControllers"] allValues] lastObject]];
        }
        else {
            principalClass = [bundle principalClass];
        }
        
        _SBUIWidgetViewController <CCSection, BBWeeAppController> *section = [[principalClass alloc] init];

         if (type == CCBundleTypeWeeApp) {
             [section setWidgetHost:self];
         }
        
        [self _CCLoader_setSection:section];

        [section release];
        
        if (type == CCBundleTypeDefault && [selfSection respondsToSelector:@selector(setDelegate:)]) {
            [section setDelegate:self];
        }
    }
    return self;
}

- (void)dealloc {
    %orig;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CCWillAppearNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CCDidAppearNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CCWillDisappearNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CCDidDisappearNotification" object:nil];
    
    if (selfBundleType == CCBundleTypeWeeApp) {
        [selfSection willMoveToParentViewController:nil];
        [selfView _CCLoader_setContentView:nil];
        [selfSection removeFromParentViewController];
    }
    else {
        [selfView _CCLoader_setContentView:nil];
    }
    
    [selfSection setWidgetHost:nil];
    
    [self _CCLoader_setSection:nil];
    
    [self.view release];
    self.view = nil;
    
    [self._CCLoader_bundle unload];

    [self _CCLoader_setBundle:nil];
    
    [self _CCLoader_setReplacingSectionViewController:nil];
}

#pragma mark - _SBUIWidgetHost

%new
- (void)invalidatePreferredViewSize {
    [self.delegate noteSectionEnabledStateDidChange:self];
}

%new
- (void)requestLaunchOfURL:(NSURL *)url {
    [[UIApplication sharedApplication] openURL:url];
}

%new
- (void)requestPresentationOfViewController:(NSString *)arg1 presentationStyle:(long long)arg2 context:(NSDictionary *)arg3 completion:(void (^)(void))arg4 {
    //??
}


#pragma mark - CCSectionDelegate

%new
- (void)_CCLoader_showViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void (^)(void))completion {
    [MSHookIvar<UIViewController *>([%c(SBControlCenterController) sharedInstance], "_viewController") presentViewController:vc animated:animated completion:completion];
}

%new
- (void)_CCLoader_updateStatusText:(NSString *)text {
    [self.delegate section:self updateStatusText:text reason:@"de.j-gessner.ccloader.updatestatustext"];
}

%new
- (void)_CCLoader_requestControlCenterDismissal {
    if (!self.view.superview) {
        NSLog(@"[CCLoader] ERROR: %@ was called too early", NSStringFromSelector(_cmd));
    }
    else {
        [self.delegate sectionWantsControlCenterDismissal:self];
    }
}

%new
- (CCBundleType)_CCLoader_bundleType {
    return (CCBundleType)[objc_getAssociatedObject(self, @selector(bundleType)) unsignedIntegerValue];
}

%new
- (void)_CCLoader_setReplacingSectionViewController:(SBControlCenterSectionViewController *)controller {
    objc_setAssociatedObject(self, @selector(replacingSection), controller, OBJC_ASSOCIATION_ASSIGN);
}

%new
- (SBControlCenterSectionViewController *)_CCLoader_replacingSectionViewController {
    return objc_getAssociatedObject(self, @selector(replacingSection));
}

%new
- (void)_CCLoader_setBundle:(NSBundle *)bundle {
    objc_setAssociatedObject(self, @selector(bundle), bundle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new
- (NSBundle *)_CCLoader_bundle {
    return objc_getAssociatedObject(self, @selector(bundle));
}

%new
- (void)_CCLoader_setSection:(id <CCSection>)section {
    objc_setAssociatedObject(self, @selector(section), section, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new
- (id <CCSection>)_CCLoader_section {
    return objc_getAssociatedObject(self, @selector(section));
}

- (void)loadView {
    CCSectionView *view = [[%c(CCSectionView) alloc] init];
    
    if (selfBundleType == CCBundleTypeDefault) {
        [view _CCLoader_setContentView:selfSection.view];
    }
    else if (selfBundleType == CCBundleTypeWeeApp) {
        [self addChildViewController:selfSection];
        
        [view _CCLoader_setContentView:selfSection.view];
        
        [selfSection didMoveToParentViewController:self];
    }
    
    self.view = view;
}

%new
- (void)_CCLoader_controlCenterWillAppear {
    if (selfBundleType && CCBundleTypeDefault && [selfSection respondsToSelector:@selector(controlCenterWillAppear)]) {
        [selfSection controlCenterWillAppear];
    }
    else if (selfBundleType == CCBundleTypeBBWeeApp) {
        if ([selfSection respondsToSelector:@selector(loadView)]) {
            [selfSection loadView];
        }
        
        if ([selfSection respondsToSelector:@selector(loadPlaceholderView)]) {
            [selfSection loadPlaceholderView];
        }
        
        if ([selfSection respondsToSelector:@selector(viewWillAppear)]) {
            [selfSection viewWillAppear];
        }
        
        UIView *contentView = selfSection.view;
        
        for (UIView *sub in contentView.subviews) {
            if ([sub isKindOfClass:[UIImageView class]]) {
                [sub removeFromSuperview];
                break;
            }
        }
        
        [selfView _CCLoader_setContentView:contentView];
    }
    else if (selfBundleType == CCBundleTypeWeeApp) {
        [selfSection hostWillPresent];
    }
}

%new
- (void)_CCLoader_controlCenterDidAppear {
    if (selfBundleType == CCBundleTypeBBWeeApp) {
        if ([selfSection respondsToSelector:@selector(loadFullView)]) {
            [selfSection loadFullView];
        }
        
        if ([selfSection respondsToSelector:@selector(viewDidAppear)]) {
            [selfSection viewDidAppear];
        }
    }
    else if (selfBundleType == CCBundleTypeWeeApp) {
        [selfSection hostDidPresent];
    }
}


%new
- (void)_CCLoader_controlCenterWillDisappear {
}


%new
- (void)_CCLoader_controlCenterDidDisappear {
    if (selfBundleType && CCBundleTypeDefault && [selfSection respondsToSelector:@selector(controlCenterDidDisappear)]) {
        [selfSection controlCenterDidDisappear];
    }
    else if (selfBundleType == CCBundleTypeBBWeeApp) {
        if ([selfSection respondsToSelector:@selector(unloadView)]) {
            [selfSection unloadView];
        }
        
        if ([selfSection respondsToSelector:@selector(viewWillDisappear)]) {
            [selfSection viewWillDisappear];
        }
        if ([selfSection respondsToSelector:@selector(viewDidDisappear)]) {
            [selfSection viewDidDisappear];
        }
        
        [selfView _CCLoader_setContentView:nil];
    }
    else if (selfBundleType == CCBundleTypeWeeApp) {
        [selfSection hostWillDismiss];
        
        [selfSection hostDidDismiss];
    }
}



- (NSString *)sectionIdentifier {
    return [self._CCLoader_bundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
}


%new
- (CGFloat)_CCLoader_height {
    if (selfBundleType == CCBundleTypeDefault) {
        return [selfSection sectionHeight];
    }
    else if (selfBundleType == CCBundleTypeBBWeeApp) {
        if ([selfSection respondsToSelector:@selector(viewHeight)]) {
            return [selfSection viewHeight];
        }
        else {
            return 80.0f; //What?
        }
    }
    else if (selfBundleType == CCBundleTypeWeeApp) {
        return [selfSection preferredViewSize].height;
    }
    else {
        return 0.0f;
    }
}

- (BOOL)enabledForOrientation:(UIInterfaceOrientation)orientation {
    return YES;
}

- (CGSize)contentSizeForOrientation:(UIInterfaceOrientation)orientation {
    SBControlCenterSectionViewController *replacingSection = self._CCLoader_replacingSectionViewController;
    
    CGFloat height = self._CCLoader_height;
    
    if (replacingSection) {
        if (height != CGFLOAT_MIN && !UIInterfaceOrientationIsLandscape(orientation) && !iPad) {
            return CGSizeMake(CGFLOAT_MAX, height);
        }
        else {
            return [replacingSection contentSizeForOrientation:orientation];
        }
    }
    else {
        return CGSizeMake(CGFLOAT_MAX, height);
    }
}


- (NSUInteger)hash {
    return [self.sectionIdentifier hash];
}

- (BOOL)isEqual:(id)other {
    if ([other isKindOfClass:%c(SBControlCenterSectionViewController)] && [other hash] == self.hash) {
        return YES;
    }
    return NO;
}

%end

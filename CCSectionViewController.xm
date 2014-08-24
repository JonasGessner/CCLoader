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


@interface EKCalendarWidgetViewController : _SBUIWidgetViewController

- (void)_refreshDayView;

@end

@interface StocksWeeAppController : _SBUIWidgetViewController

@end


#define iPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#define selfView ((CCSectionView *)self.view)

#define selfSection self._CCLoader_section

#define selfBundleType self._CCLoader_bundleType

@interface CCSectionViewController ()

- (void)_CCLoader_setBundle:(NSBundle *)bundle;

- (void)_CCLoader_setSection:(_SBUIWidgetViewController <CCSection, BBWeeAppController> *)section;
- (_SBUIWidgetViewController <CCSection, BBWeeAppController> *)_CCLoader_section;

- (CCBundleType)_CCLoader_bundleType;

- (void)showViewController:(UIViewController *)vc animated:(BOOL)animated modalPresentationStyle:(UIModalPresentationStyle)style completion:(void (^)(void))completion;

@end

%subclass CCSectionViewController : SBControlCenterSectionViewController <CCSectionDelegate, _SBUIWidgetHost>

%new
- (id)initWithCCLoaderBundle:(NSBundle *)bundle type:(CCBundleType)type {
    self = [self init];
    if (self) {
        objc_setAssociatedObject(self, @selector(bundleType), @(type), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_CCLoader_controlCenterWillAppear) name:@"CCLoaderCCWillAppearNotification" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_CCLoader_controlCenterDidAppear) name:@"CCLoaderCCDidAppearNotification" object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_CCLoader_controlCenterWillDisappear) name:@"CCLoaderCCWillDisappearNotification" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_CCLoader_controlCenterDidDisappear) name:@"CCLoaderCCDidDisappearNotification" object:nil];
        
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
        else if (type == CCBundleTypeDefault && [selfSection respondsToSelector:@selector(setDelegate:)]) {
            [section setDelegate:self];
        }
        
        [self _CCLoader_setSection:section];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CCLoaderCCWillAppearNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CCLoaderCCDidAppearNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CCLoaderCCWillDisappearNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CCLoaderCCDidDisappearNotification" object:nil];
    
    if (selfBundleType == CCBundleTypeWeeApp) {
        [selfSection setWidgetHost:nil];
    }
    else if (selfBundleType == CCBundleTypeDefault && [selfSection respondsToSelector:@selector(setDelegate:)]) {
        [selfSection setDelegate:nil];
    }
    
    [selfView _CCLoader_setContentView:nil];
    
    [selfSection release];
    [self _CCLoader_setSection:nil];
    
    [self.view release];
    self.view = nil;

    if (selfBundleType == CCBundleTypeDefault) {
        [self._CCLoader_bundle unload];
    }
    
    [self _CCLoader_setBundle:nil];

    [self _CCLoader_setReplacingSectionViewController:nil];
    
    %orig;
}

%new
- (void)showViewController:(UIViewController *)vc animated:(BOOL)animated modalPresentationStyle:(UIModalPresentationStyle)style completion:(void (^)(void))completion {
    UIViewController *viewController = MSHookIvar<UIViewController *>([%c(SBControlCenterController) sharedInstance], "_viewController");
    
    [viewController setModalPresentationStyle:style];
    
    [viewController presentViewController:vc animated:animated completion:completion];
}

#pragma mark - _SBUIWidgetHost

%new
- (void)invalidatePreferredViewSize {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CCLoaderReloadControlCenterHeight" object:nil];
}

%new
- (void)requestLaunchOfURL:(NSURL *)url {
    [[UIApplication sharedApplication] openURL:url];
}

%new
- (void)requestPresentationOfViewController:(UIViewController *)present presentationStyle:(UIModalPresentationStyle)presentationStyle context:(NSDictionary *)info completion:(void (^)(void))completion {
    [self showViewController:present animated:YES modalPresentationStyle:presentationStyle completion:completion];
}


#pragma mark - CCSectionDelegate

%new
- (void)showViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void (^)(void))completion {
    [self showViewController:vc animated:animated modalPresentationStyle:UIModalPresentationFullScreen completion:completion];
}

%new
- (void)updateStatusText:(NSString *)text {
    [self.delegate section:self updateStatusText:text reason:@"de.j-gessner.ccloader.updatestatustext"];
}

%new
- (void)requestControlCenterDismissal {
    if (!self.view.superview) {
        NSLog(@"[CCLoader] ERROR: %@ was called too early", NSStringFromSelector(_cmd));
    }
    else {
        [self.delegate sectionWantsControlCenterDismissal:self];
    }
}

%new
- (void)sectionHeightChanged {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CCLoaderReloadControlCenterHeight" object:nil];
}

#pragma mark -

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
- (void)_CCLoader_setBundle:(NSBundle *)_bundle {
    objc_setAssociatedObject(self, @selector(bundle), _bundle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new
- (NSBundle *)_CCLoader_bundle {
    return objc_getAssociatedObject(self, @selector(bundle));
}

%new
- (void)_CCLoader_setSection:(id <CCSection>)_section {
    objc_setAssociatedObject(self, @selector(section), _section, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    if (selfBundleType == CCBundleTypeDefault && [selfSection respondsToSelector:@selector(controlCenterWillAppear)]) {
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
        
        //For some reason this needs to be here or the Calendar Widget won't be displayed correctly after the first dismissal?
        if ([selfSection isKindOfClass:%c(EKCalendarWidgetViewController)] && [selfSection respondsToSelector:@selector(_refreshDayView)]) {
            [(EKCalendarWidgetViewController *)selfSection _refreshDayView];
        }
    }
}


%new
- (void)_CCLoader_controlCenterWillDisappear {
    
}


%new
- (void)_CCLoader_controlCenterDidDisappear {
    if (selfBundleType == CCBundleTypeDefault && [selfSection respondsToSelector:@selector(controlCenterDidDisappear)]) {
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
        
        BOOL stocksWeeApp = ([selfSection isKindOfClass:%c(StocksWeeAppController)]);
        
        if (stocksWeeApp) {
            [selfSection setWidgetHost:nil];
        }
        
        [selfSection hostDidDismiss];
        
        if (stocksWeeApp) {
            [selfSection setWidgetHost:self];
        }
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
            return 80.0f;
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
//        NSLog(@"RETURNING SIZE %@", NSStringFromCGSize([replacingSection contentSizeForOrientation:orientation]));
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

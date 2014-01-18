//
//  CCSectionViewController.x
//  CCLoader
//
//  Created by Jonas Gessner on 04.01.2014.
//  Copyright (c) 2014 Jonas Gessner. All rights reserved.
//

#import "CCSectionViewController.h"
#import "CCSectionView.h"

#import "CCLoaderSettings/SpringBoardUIServices/_SBUIWidgetViewController.h"

#import "CCLoaderSettings/BBWeeAppController-Protocol.h"

#import <objc/runtime.h>
#include <substrate.h>

@interface CCSectionViewController ()

- (void)setBundle:(NSBundle *)bundle;

- (void)setSection:(_SBUIWidgetViewController <CCSection, BBWeeAppController> *)section;
- (_SBUIWidgetViewController <CCSection, BBWeeAppController> *)section;

- (CCBundleType)bundleType;

@end

%subclass CCSectionViewController : SBControlCenterSectionViewController <CCSectionDelegate>

%new
- (id)initWithBundle:(NSBundle *)bundle type:(CCBundleType)type {
    self = [self init];
    if (self) {
        objc_setAssociatedObject(self, @selector(bundleType), @(type), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_CC_controlCenterWillAppear) name:@"CCWillAppearNotification" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_CC_controlCenterDidAppear) name:@"CCDidAppearNotification" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_CC_controlCenterDidDisappear) name:@"CCDidDisappearNotification" object:nil];
        
        [self setBundle:bundle];

        Class principalClass = [self.bundle principalClass];
        
        _SBUIWidgetViewController <CCSection, BBWeeAppController> *section = [[principalClass alloc] init];

        [self setSection:section];
        
        [section release];

        if (type == CCBundleTypeDefault && [self.section respondsToSelector:@selector(setDelegate:)]) {
            [self.section setDelegate:self];
        }
    }
    return self;
}

- (void)dealloc {
    %orig;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CCWillAppearNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CCDidAppearNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CCDidDisappearNotification" object:nil];
    
    [self setSection:nil];
    
    [self.view release];
    self.view = nil;
    
    [self.bundle unload];

    [self setBundle:nil];
    
    [self setReplacingSectionViewController:nil];
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
- (CCBundleType)bundleType {
    return (CCBundleType)[objc_getAssociatedObject(self, @selector(bundleType)) unsignedIntegerValue];
}

%new
- (void)setReplacingSectionViewController:(SBControlCenterSectionViewController *)controller {
    objc_setAssociatedObject(self, @selector(replacingSection), controller, OBJC_ASSOCIATION_ASSIGN);
}

%new
- (SBControlCenterSectionViewController *)replacingSectionViewController {
    return objc_getAssociatedObject(self, @selector(replacingSection));
}

%new
- (void)setBundle:(NSBundle *)bundle {
    objc_setAssociatedObject(self, @selector(bundle), bundle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new
- (NSBundle *)bundle {
    return objc_getAssociatedObject(self, @selector(bundle));
}

%new
- (void)setSection:(id <CCSection>)section {
    objc_setAssociatedObject(self, @selector(section), section, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new
- (id <CCSection>)section {
    return objc_getAssociatedObject(self, @selector(section));
}

- (void)loadView {
    CCSectionView *view = [[%c(CCSectionView) alloc] init];

    if (self.bundleType == CCBundleTypeDefault || self.bundleType == CCBundleTypeWeeApp) {
        UIView *contentView = [self.section view];
        
        [view setContentView:contentView];
    }
    
    self.view = view;
}

%new
- (void)_CC_controlCenterWillAppear {
    if (self.bundleType && CCBundleTypeDefault && [self.section respondsToSelector:@selector(controlCenterWillAppear)]) {
        [self.section controlCenterWillAppear];
    }
    else if (self.bundleType == CCBundleTypeBBWeeApp) {
        if ([self.section respondsToSelector:@selector(loadView)]) {
            [self.section loadView];
        }
        
        if ([self.section respondsToSelector:@selector(loadPlaceholderView)]) {
            [self.section loadPlaceholderView];
        }
        
        UIView *contentView = self.section.view;
        
        for (UIView *sub in contentView.subviews) {
            if ([sub isKindOfClass:[UIImageView class]]) {
                [sub removeFromSuperview];
                break;
            }
        }
        
        [((CCSectionView *)self.view) setContentView:contentView];
        
        if ([self.section respondsToSelector:@selector(viewWillAppear)]) {
            [self.section viewWillAppear];
        }
    }
    else if (self.bundleType == CCBundleTypeWeeApp) {
        [self.section __hostWillPresent];
        [self.section hostWillPresent];
        
        [self.section viewWillAppear];
    }
}

%new
- (void)_CC_controlCenterDidAppear {
    if (self.bundleType == CCBundleTypeBBWeeApp) {
        
        if ([self.section respondsToSelector:@selector(loadFullView)]) {
            [self.section loadFullView];
        }
        
        if ([self.section respondsToSelector:@selector(viewDidAppear)]) {
            [self.section viewDidAppear];
        }
    }
    else if (self.bundleType == CCBundleTypeWeeApp) {
        [self.section viewDidAppear];
        
        [self.section __hostDidPresent];
        [self.section hostDidPresent];
    }
}

%new
- (void)_CC_controlCenterDidDisappear {
    if (self.bundleType && CCBundleTypeDefault && [self.section respondsToSelector:@selector(controlCenterDidDisappear)]) {
        [self.section controlCenterDidDisappear];
    }
    else if (self.bundleType == CCBundleTypeBBWeeApp) {
        if ([self.section respondsToSelector:@selector(unloadView)]) {
            [self.section unloadView];
        }
        
        if ([self.section respondsToSelector:@selector(viewWillDisappear)]) {
            [self.section viewWillDisappear];
        }
        if ([self.section respondsToSelector:@selector(viewDidDisappear)]) {
            [self.section viewDidDisappear];
        }
        
        [((CCSectionView *)self.view) setContentView:nil];
    }
    else if (self.bundleType == CCBundleTypeWeeApp) {
        [self.section __hostWillDismiss];
        [self.section hostWillDismiss];
        
        [self.section viewWillDisappear];
        [self.section viewDidDisappear];
        
        [self.section __hostDidDismiss];
        [self.section hostDidDismiss];
    }
}



- (NSString *)sectionIdentifier {
    return [self.bundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
}

- (NSString *)sectionName {
    return [self.bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
}



%new
- (CGFloat)height {
    if (self.bundleType == CCBundleTypeDefault) {
        return [self.section sectionHeight];
    }
    else if (self.bundleType == CCBundleTypeBBWeeApp) {
        if ([self.section respondsToSelector:@selector(viewHeight)]) {
            return [self.section viewHeight];
        }
        else {
            return 80.0f;
        }
    }
    else if (self.bundleType == CCBundleTypeWeeApp) {
        return [self.section preferredViewSize].height;
    }
    else {
        NSLog(@"ZEROROROROROROROROROROROROROROR");
        return 0.0f; //Damn son, if this ever happens then you've messed up big time.
    }
}

- (BOOL)enabledForOrientation:(UIInterfaceOrientation)orientation {
    return YES;
}

- (CGSize)contentSizeForOrientation:(UIInterfaceOrientation)orientation {
    SBControlCenterSectionViewController *replacingSection = self.replacingSectionViewController;
    
    if (replacingSection) {
        return [replacingSection contentSizeForOrientation:orientation];
    }
    else {
        return CGSizeMake(CGFLOAT_MAX, self.height);
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

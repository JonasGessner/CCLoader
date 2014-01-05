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

#import "CCBundleLoader.h"
#import "CCSectionViewController.h"
#import "CCScrollView.h"

#import "ControlCenter/SBControlCenterViewController.h"
#import "ControlCenter/SBControlCenterContainerView.h"
#import "ControlCenter/SBControlCenterContentContainerView.h"


static NSArray *customSections = nil;

NS_INLINE void loadCCSections(void) {
    NSCAssert(!customSections, @"Sections already loaded");
    
    CCBundleLoader *loader = [CCBundleLoader sharedInstance];
    [loader loadBundles];
    
    NSMutableArray *sectionViewControllers = [NSMutableArray array];
    
    for (NSBundle *bundle in loader.bundles) {
        CCSectionViewController *sectionViewController = [[%c(CCSectionViewController) alloc] initWithBundle:bundle];
        
        [sectionViewControllers addObject:sectionViewController];
    }
    
    customSections = sectionViewControllers.copy;
}



static BOOL landscape = NO;

static CGFloat realHeight = 0.0f;

static CCScrollView *scroller = nil;


%group main

%hook SBControlCenterContentContainerView

- (void)layoutSubviews {
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
    }
    
    if (scroller.superview != self) {
        [self addSubview:scroller];
    }
    
    UIView *contentView = MSHookIvar<UIView *>(self, "_contentView");
    
    if (contentView.superview != scroller) {
        [scroller addSubview:contentView];
    }
    
    CGRect frame = self.bounds;
    
    scroller.frame = frame;
    
    frame.size.height = realHeight;
    
    scroller.contentSize = frame.size;
}

- (void)setFrame:(CGRect)frame {
    if (landscape) {
        return %orig;
    }
    
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    if (frame.size.height > screenHeight) {
        frame.size.height = screenHeight;
    }
    
    %orig;
}

- (void)setBounds:(CGRect)frame {
    if (landscape) {
        return %orig;
    }
    
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    if (frame.size.height > screenHeight) {
        frame.size.height = screenHeight;
    }
    
    %orig;
}

%end


%hook SBControlCenterContentView

- (void)setFrame:(CGRect)frame {
    if (landscape) {
        return %orig;
    }
    
    frame.size.height = realHeight;
    
    %orig;
}

- (NSMutableArray *)_allSections {
    if (landscape) {
        return %orig;
    }
    
    NSMutableArray *sections = %orig;
    
    [sections addObjectsFromArray:customSections];
    
    return sections;
}

%end

%hook SBControlCenterViewController

- (CGFloat)contentHeightForOrientation:(UIInterfaceOrientation)orientation {
    landscape = UIInterfaceOrientationIsLandscape(orientation);
    
    CGFloat height = %orig;
    
    if (landscape) {
        return height;
    }
    
    realHeight = height;
    
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    if (height > screenHeight) {
        height = screenHeight;
    }
    
    return height;
}

- (void)loadView {
    loadCCSections();
    %orig;
}

%end

%end


%ctor {
	@autoreleasepool {
		%init(main);
	}
}

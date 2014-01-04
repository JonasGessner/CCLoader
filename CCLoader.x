//
//  CCLoader.x
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

#import "ControlCenter/SBControlCenterViewController.h"

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

%group main

%hook SBControlCenterContentView

- (NSMutableArray *)_allSections {
    NSMutableArray *sections = %orig;
    
    if (!landscape) {
        [sections addObjectsFromArray:customSections];
    }
    
    return sections;
}

%end

%hook SBControlCenterViewController

- (void)controlCenterWillPresent {
    landscape = UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
    %orig;
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

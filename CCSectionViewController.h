//
//  CCSectionViewController.h
//  CCLoader
//
//  Created by Jonas Gessner on 04.01.2014.
//  Copyright (c) 2014 Jonas Gessner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "ControlCenter/SBControlCenterSectionViewController.h"
#import "ControlCenter/SBControlCenterSectionView.h"

#import "CCLoaderSettings/CCSection-Protocol.h"

typedef NS_ENUM(NSUInteger, CCBundleType) {
    CCBundleTypeDefault,
    CCBundleTypeWeeApp,
    CCBundleTypeBBWeeApp
};

@interface CCSectionViewController : SBControlCenterSectionViewController <CCSectionDelegate>

- (id)initWithBundle:(NSBundle *)bundle type:(CCBundleType)type;

- (void)setReplacingSectionViewController:(SBControlCenterSectionViewController *)controller;
- (SBControlCenterSectionViewController *)replacingSectionViewController;

- (NSString *)sectionName;
- (NSString *)sectionIdentifier;

- (NSBundle *)bundle;

//Unused when replacing a stock section
- (CGFloat)height;

@end
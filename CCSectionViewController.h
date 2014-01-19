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

#import "CCLoaderSettings/SpringBoardUIServices/_SBUIWidgetHost.h"

#import "CCLoaderSettings/CCSection-Protocol.h"

typedef NS_ENUM(NSUInteger, CCBundleType) {
    CCBundleTypeDefault,
    CCBundleTypeWeeApp,
    CCBundleTypeBBWeeApp
};

@interface CCSectionViewController : SBControlCenterSectionViewController <CCSectionDelegate, _SBUIWidgetHost>

- (id)initWithCCLoaderBundle:(NSBundle *)bundle type:(CCBundleType)type;

- (void)_CCLoader_setReplacingSectionViewController:(SBControlCenterSectionViewController *)controller;
- (SBControlCenterSectionViewController *)_CCLoader_replacingSectionViewController;

- (NSBundle *)_CCLoader_bundle;

//Unused when replacing a stock section
- (CGFloat)_CCLoader_height;

@end
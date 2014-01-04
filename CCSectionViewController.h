//
//  CCSectionViewController.h
//  CCLoader
//
//  Created by Jonas Gessner on 04.01.2014.
//  Copyright (c) 2014 Jonas Gessner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "SBControlCenterSectionViewController.h"
#import "SBControlCenterSectionView.h"

@interface CCSectionViewController : SBControlCenterSectionViewController

- (id)initWithBundle:(NSBundle *)bundle;

- (NSString *)sectionName;
- (NSString *)sectionIdentifier;

- (NSBundle *)bundle;

@end
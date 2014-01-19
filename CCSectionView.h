//
//  CCSectionViewController.h
//  CCLoader
//
//  Created by Jonas Gessner on 04.01.2014.
//  Copyright (c) 2014 Jonas Gessner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "ControlCenter/SBControlCenterSectionView.h"

@interface CCSectionView : SBControlCenterSectionView

- (void)_CCLoader_setContentView:(UIView *)view;

- (UIView *)_CCLoader_contentView;

@end
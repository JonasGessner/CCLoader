//
//  CCSectionView.x
//  CCLoader
//
//  Created by Jonas Gessner on 04.01.2014.
//  Copyright (c) 2014 Jonas Gessner. All rights reserved.
//

#import "CCSectionView.h"

#import <objc/runtime.h>
#include <substrate.h>

@interface CCSectionView ()

- (void)setContentView:(UIView *)view;

@end

%subclass CCSectionView : SBControlCenterSectionView

- (void)dealloc {
    %orig;
    
    [self setContentView:nil];
}

%new
- (void)setContentView:(UIView *)view {
    [self.contentView removeFromSuperview];
    
    if (view) {
        [self addSubview:view];
    }
    
    objc_setAssociatedObject(self, @selector(contentView), view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new
- (UIView *)contentView {
    return objc_getAssociatedObject(self, @selector(contentView));
}

- (void)layoutSubviews {
    %orig;
    
    self.contentView.frame = self.bounds;
}

%end

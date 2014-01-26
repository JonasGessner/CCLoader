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

%subclass CCSectionView : SBControlCenterSectionView

- (void)dealloc {
    [self _CCLoader_setContentView:nil];
    
    %orig;
}

%new
- (void)_CCLoader_setContentView:(UIView *)view {
    [self._CCLoader_contentView removeFromSuperview];
    
    if (view) {
        [self addSubview:view];
    }
    
    objc_setAssociatedObject(self, @selector(contentView), view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new
- (UIView *)_CCLoader_contentView {
    return objc_getAssociatedObject(self, @selector(contentView));
}

- (void)layoutSubviews {
    %orig;
    
    self._CCLoader_contentView.frame = self.bounds;
}

%end

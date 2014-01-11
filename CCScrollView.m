//
//  CCScrollView.m
//  CCLoader
//
//  Created by Jonas Gessner on 04.01.2014.
//  Copyright (c) 2014 Jonas Gessner. All rights reserved.
//

#import "CCScrollView.h"

@implementation CCScrollView

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer locationInView:self].y-self.contentOffset.y <= 10.0f) {
        return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    if (hit == self) {
        return nil;
    }
    else {
        return hit;
    }
}

@end
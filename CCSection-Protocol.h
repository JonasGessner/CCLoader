#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol CCSection <NSObject>

@required
- (UIView *)view;

- (CGFloat)sectionHeight;

@optional
- (void)viewWillAppear;
- (void)viewDidAppear;

- (void)viewWillDisappear;
- (void)viewDidDisappear;

@end

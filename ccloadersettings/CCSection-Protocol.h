#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol CCSectionDelegate <NSObject>

- (void)updateStatusText:(NSString *)text;
- (void)requestControlCenterDismissal;
- (void)sectionHeightChanged;
- (void)showViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void (^)(void))completion;

@end

@protocol CCSection <NSObject>

@required
/**
 Return a valid view with your contents here.
 */
- (UIView *)view;

/**
 Return the desired height of the section here. For sections that replace a stock section, returning CGFLOAT_MIN will result in the equal height of the section that is being replaced.
 */
- (CGFloat)sectionHeight;

@optional
- (void)setDelegate:(UIViewController <CCSectionDelegate> *)delegate;

- (void)controlCenterWillAppear;

- (void)controlCenterDidDisappear;

/**
 If the section is not ready or available for display return YES and the section will not be displayed, or the stock section will be displayed for a replacing section.
 */
+ (BOOL)isUnavailable;

@end

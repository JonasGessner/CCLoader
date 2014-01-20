//
//     Generated by class-dump 3.4 (64 bit) (Debug version compiled Oct  5 2013 12:36:13).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2012 by Steve Nygard.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

#import "_SBUIWidgetHost.h"
#import "_SBUIWidgetViewController_Remote_IPC.h"

@class NSString;

@interface _SBUIWidgetViewController : UIViewController <_SBUIWidgetHost, _SBUIWidgetViewController_Remote_IPC>
{
    long long _widgetIdiom;
    NSString *_widgetidentifier;
    id <_SBUIWidgetHost> _widgetHost;
    NSString *_widgetIdentifier;
}

+ (id)_exportedInterface;
+ (id)_remoteViewControllerInterface;
@property(nonatomic, assign) id <_SBUIWidgetHost> widgetHost; // @synthesize widgetHost=_widgetHost;
@property(copy, nonatomic) NSString *widgetIdentifier; // @synthesize widgetIdentifier=_widgetIdentifier;
@property(nonatomic, assign) long long widgetIdiom; // @synthesize widgetIdiom=_widgetIdiom;
- (void)__hostDidDismiss;
- (void)__hostWillDismiss;
- (void)__hostDidPresent;
- (void)__hostWillPresent;
- (void)__setWidgetIdiom:(long long)arg1;
- (void)__setWidgetIdentifier:(id)arg1;
- (void)__requestPreferredViewSizeWithReplyHandler:(id)arg1;

- (void)invalidatePreferredViewSize;
- (void)requestLaunchOfURL:(id)arg1;
- (void)requestPresentationOfViewController:(id)arg1 presentationStyle:(long long)arg2 context:(id)arg3 completion:(id)arg4;
- (void)hostDidDismiss;
- (void)hostWillDismiss;
- (void)hostDidPresent;
- (void)hostWillPresent;
@property(readonly, nonatomic) CGSize preferredViewSize;
- (void)dealloc;

@end


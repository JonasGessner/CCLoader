//
//  CCLoaderSettingsListController.m
//  CCLoader Settings
//
//  Created by Jonas Gessner on 04.01.2014.
//  Copyright (c) 2014 Jonas Gessner. All rights reserved.
//

#import "CCLoaderSettingsListController.h"

#import "CCBundleLoader.h"


@interface CCLoaderSettingsListController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate> {
    NSMutableOrderedSet *_enabled;
    NSMutableOrderedSet *_disabled;
    
    NSDictionary *_displayNames;
    
    BOOL _dynamicMediaControls;
    BOOL _hideSeparators;
}

@end

@implementation CCLoaderSettingsListController

#define kYear [[[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:[NSDate date]] year]

#define kCCLoaderStockOrderedSections @[@"com.apple.controlcenter.settings", @"com.apple.controlcenter.brightness", @"com.apple.controlcenter.media-controls", @"com.apple.controlcenter.air-stuff", @"com.apple.controlcenter.quick-launch"]

#define kCCLoaderStockDisplayNames @{@"com.apple.controlcenter.settings" : @"Settings", @"com.apple.controlcenter.brightness" : @"Brightness", @"com.apple.controlcenter.media-controls" : @"Media Controls", @"com.apple.controlcenter.air-stuff" : @"AirPlay/AirDrop", @"com.apple.controlcenter.quick-launch" : @"Quick Launch"}

#define kCCLoaderStockSections [NSSet setWithArray:kCCLoaderStockOrderedSections]

#define kCCLoaderSettingsPath [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"Preferences/de.j-gessner.ccloader.plist"]

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.title = @"CCLoader";
        
        UIButton *addButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
        [addButton addTarget:self action:@selector(infoPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        UIBarButtonItem *barButtton = [[UIBarButtonItem alloc] initWithCustomView:addButton];
        
        self.navigationItem.rightBarButtonItem = barButtton;
        
        CCBundleLoader *loader = [CCBundleLoader sharedInstance];
        [loader loadBundles:NO];
        
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kCCLoaderSettingsPath];
        
        _dynamicMediaControls = [prefs[@"HideMediaControls"] boolValue];
        _hideSeparators = [prefs[@"HideSeparators"] boolValue];
        
        _enabled = [NSMutableOrderedSet orderedSetWithArray:prefs[@"EnabledSections"]];
        
        _disabled = [NSMutableOrderedSet orderedSetWithArray:prefs[@"DisabledSections"]];
        
        NSMutableDictionary *displayNames = [kCCLoaderStockDisplayNames mutableCopy];
        
        for (NSBundle *bundle in loader.bundles) {
            NSString *ID = bundle.bundleIdentifier;
            
            NSString *displayName = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
            if (displayName) {
                displayNames[ID] = displayName;
            }
        }
        
        _displayNames = displayNames.copy;
    }
    
    return self;
}

- (void)infoPressed:(UIButton *)__unused sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"CCLoader by Jonas Gessner" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Donate", @"Twitter", @"More Apps & Tweaks", @"Source Code", nil];
    
    [sheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=gessner%40email%2eit&lc=US&item_name=Donation%20for%20CCLoader&no_note=0&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donate_LG%2egif%3aNonHostedGuest"]];
    }
    else if (buttonIndex == 1) {
        NSString *user = @"JonasGessner";
        
        NSArray *schemes = @[[NSURL URLWithString:[NSString stringWithFormat:@"twitter://user?screen_name=%@", user]], [NSURL URLWithString:[NSString stringWithFormat:@"tweetbot://%@/timeline", user]], [NSURL URLWithString:[NSString stringWithFormat:@"twitterrific:///profile?screen_name=%@", user]]];
        
        for (NSURL *URL in schemes) {
            if ([[UIApplication sharedApplication] canOpenURL:URL]) {
                [[UIApplication sharedApplication] openURL:URL];
                return;
            }
        }
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://twitter.com/%@", user]]];
        
    }
    else if (buttonIndex == 2) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://j-gessner.de/"]];
    }
    else if (buttonIndex == 3) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://github.com/JonasGessner/CCLoader"]];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    [self.tableView setEditing:YES];
}

- (void)loadView {
    UITableView *tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame style:UITableViewStyleGrouped];
    
    tableView.dataSource = self;
    tableView.delegate = self;
    
    self.view = tableView;
}

- (UITableView *)tableView {
    return (UITableView *)self.view;
}

- (void)syncPrefs:(BOOL)notificate {
    NSMutableDictionary *prefs = [NSMutableDictionary dictionary];
    
    if (_enabled) {
        prefs[@"EnabledSections"] = _enabled.array;
    }
    
    if (_disabled.count) {
        prefs[@"DisabledSections"] = _disabled.array;
    }
    
    if (_dynamicMediaControls) {
        prefs[@"HideMediaControls"] = @(YES);
    }
    
    if (_hideSeparators) {
        prefs[@"HideSeparators"] = @(YES);
    }
    
    [prefs.copy writeToFile:kCCLoaderSettingsPath atomically:YES];
    
    if (notificate) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("de.j-gessner.ccloader.settingschanged"),  NULL, NULL, true);
    }
}

- (void)dynamicSwitched:(UISwitch *)sender {
    _dynamicMediaControls = sender.on;
    
    [self syncPrefs:YES];
}

- (void)hideSeparatorsSwitched:(UISwitch *)sender {
    _hideSeparators = sender.on;
    
    [self syncPrefs:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 2) {
        return 2;
    }
    
    NSUInteger num = 0;
    
    if (section == 0) {
        num = _enabled.count;
    }
    else {
        num = _disabled.count;
    }
    
    if (!num) {
        num = 1;
    }
    
    return num;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Enabled Sections";
    }
    else if (section == 1) {
        return @"Disabled Sections";
    }
    else if (section == 2) {
        return @"Options";
    }
    else {
        return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 2) {
        return [NSString stringWithFormat:@"If no media is playing the media controls will not be shown in ControlCenter\n\n\n© Jonas Gessner %@", (2014 < kYear ? [NSString stringWithFormat:@"2014-%lu", (unsigned long)kYear] : @"2014")];
    }
    else {
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const cellID = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    
    if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            UISwitch *accessory = [UISwitch new];
            accessory.on = _hideSeparators;
            
            [accessory addTarget:self action:@selector(hideSeparatorsSwitched:) forControlEvents:UIControlEventValueChanged];
            
            cell.accessoryView = accessory;
            
            cell.textLabel.text = @"Hide Separators";
        }
        else if (indexPath.row == 1) {
            UISwitch *accessory = [UISwitch new];
            accessory.on = _dynamicMediaControls;
            
            [accessory addTarget:self action:@selector(dynamicSwitched:) forControlEvents:UIControlEventValueChanged];
            
            cell.accessoryView = accessory;
            
            cell.textLabel.text = @"Dynamic Media Controls";
        }
    }
    else if ((indexPath.section == 0 && _enabled.count) || (indexPath.section == 1 && _disabled.count)) {
        NSString *ID = (indexPath.section == 0 ? _enabled[indexPath.row] : _disabled[indexPath.row]);
        
        NSString *displayName = _displayNames[ID];
        
        cell.textLabel.text = (displayName ? : ID);
        
        cell.textLabel.alpha = 1.0f;
    }
    else {
        cell.textLabel.alpha = 0.5f;
        
        cell.textLabel.text = @"Empty";
    }
    
    return cell;
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0f;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0f;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section < 2);
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section < 2 && ((indexPath.section == 0 && _enabled.count) || (indexPath.section == 1 && _disabled.count)));
}

#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    if (proposedDestinationIndexPath.section > 1) {
        return sourceIndexPath;
    }
    else if ((proposedDestinationIndexPath.section == 0 && !_enabled.count) || (proposedDestinationIndexPath.section == 1 && !_disabled.count)) {
        return [NSIndexPath indexPathForRow:0 inSection:proposedDestinationIndexPath.section];
    }
    else {
        return proposedDestinationIndexPath;
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    [self.tableView beginUpdates];
    
    BOOL clearRow = ((destinationIndexPath.section == 0 && !_enabled.count) || (destinationIndexPath.section == 1 && !_disabled.count));
    
    if (sourceIndexPath.section == 0) {
        NSString *sourceID = _enabled[sourceIndexPath.row];
        
        [_enabled removeObjectAtIndex:sourceIndexPath.row];
        
        if (destinationIndexPath.section == 0) {
            [_enabled insertObject:sourceID atIndex:destinationIndexPath.row];
        }
        else {
            [_disabled insertObject:sourceID atIndex:(clearRow ? 0 : destinationIndexPath.row)];
        }
    }
    else if (sourceIndexPath.section == 1) {
        NSString *sourceID = _disabled[sourceIndexPath.row];
        
        [_disabled removeObjectAtIndex:sourceIndexPath.row];
        
        if (destinationIndexPath.section == 1) {
            [_disabled insertObject:sourceID atIndex:destinationIndexPath.row];
        }
        else {
            [_enabled insertObject:sourceID atIndex:(clearRow ? 0 : destinationIndexPath.row)];
        }
    }
    
    if (clearRow) {
        NSIndexPath *remove = [NSIndexPath indexPathForRow:destinationIndexPath.section inSection:destinationIndexPath.section];
        
        [self.tableView deleteRowsAtIndexPaths:@[remove] withRowAnimation:UITableViewRowAnimationNone];
    }
    
    BOOL insertRow = ((sourceIndexPath.section == 0 && !_enabled.count) || (sourceIndexPath.section == 1 && !_disabled.count));
    
    if (insertRow) {
        NSIndexPath *add = [NSIndexPath indexPathForRow:0 inSection:sourceIndexPath.section];
        
        [self.tableView insertRowsAtIndexPaths:@[add] withRowAnimation:UITableViewRowAnimationFade];
    }
    
    [self.tableView endUpdates];
    
    [self syncPrefs:YES];
}

@end

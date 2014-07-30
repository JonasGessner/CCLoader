//
//  CCLoaderSettingsListController.m
//  CCLoader Settings
//
//  Created by Jonas Gessner on 04.01.2014.
//  Copyright (c) 2014 Jonas Gessner. All rights reserved.
//

#import "CCLoaderSettingsListController.h"

#import "CCLoaderReplacementsViewController.h"

#import "CCBundleLoader.h"


#define rgba(r, g, b, a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]
#define rgb(r, g, b) rgba(r, g, b, 1.0f)

#define iPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

@interface CCLoaderSettingsListController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate> {
    NSMutableOrderedSet *_enabled;
    NSMutableOrderedSet *_disabled;
    
    NSMutableDictionary *_replacements;
    
    BOOL _dynamicMediaControls;
    BOOL _hideSeparators;
}

@end

@implementation CCLoaderSettingsListController

#define kYear [[[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:[NSDate date]] year]

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
        
        [loader loadBundlesAndReplacements:YES loadNames:YES checkBundles:NO];
        
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kCCLoaderSettingsPath];
        
        _dynamicMediaControls = [prefs[@"HideMediaControls"] boolValue];
        
        NSNumber *hideSep = prefs[@"HideSeparators"];
        
        if (hideSep) {
            _hideSeparators = [prefs[@"HideSeparators"] boolValue];
        }
        
        _enabled = (iPad ? [NSMutableOrderedSet orderedSetWithArray:kCCLoaderStockOrderedSections] : [NSMutableOrderedSet orderedSetWithArray:prefs[@"EnabledSections"]]);
        
        _disabled = (iPad ? nil : [NSMutableOrderedSet orderedSetWithArray:prefs[@"DisabledSections"]]);
        
        _replacements = [prefs[@"ReplacingBundles"] mutableCopy];
    }
    
    return self;
}

- (void)infoPressed:(UIButton *)__unused sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"CCLoader by Jonas Gessner" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Donate", @"Twitter", @"More Apps & Tweaks", @"API Info & Source Code", nil];
    
    [sheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
}

- (void)willPresentActionSheet:(UIActionSheet *)sheet {
    for (UIButton *button in sheet.subviews) {
        if ([button isKindOfClass:[UIButton class]]) {
            UIColor *color = rgb(35.0f, 180.0f, 90.0f);
            
            [button setTitleColor:color forState:UIControlStateNormal];
            [button setTitleColor:color forState:UIControlStateSelected];
            [button setTitleColor:color forState:UIControlStateHighlighted];
            
            break;
        }
    }
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
    
    [self.tableView setAllowsSelectionDuringEditing:YES];
    
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
    
    if (_replacements) {
        prefs[@"ReplacingBundles"] = _replacements;
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
    _hideSeparators = !sender.on;
    
    [self syncPrefs:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (iPad ? 2 : 3);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 2-iPad) {
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
    if (iPad) {
        if (section == 0) {
            return @"Control Center Sections";
        }
        else if (section == 2) {
            return @"Options";
        }
        else {
            return nil;
        }
    }
    else {
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
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 2-iPad) {
        return [NSString stringWithFormat:@"Dynamic Media Controls: If no media is playing the media controls will not be shown in Control Center.\n\n\n© %@ Jonas Gessner", (2014 < kYear ? [NSString stringWithFormat:@"2014-%lu", (unsigned long)kYear] : @"2014")];
    }
    else {
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const cellID = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    
    if (indexPath.section == 2-iPad) {
        if (indexPath.row == 0) {
            UISwitch *accessory = [UISwitch new];
            accessory.on = !_hideSeparators;
            
            [accessory addTarget:self action:@selector(hideSeparatorsSwitched:) forControlEvents:UIControlEventValueChanged];
            
            cell.accessoryView = accessory;
            
            cell.textLabel.text = @"Show Separators";
        }
        else if (indexPath.row == 1) {
            UISwitch *accessory = [UISwitch new];
            accessory.on = _dynamicMediaControls;
            
            [accessory addTarget:self action:@selector(dynamicSwitched:) forControlEvents:UIControlEventValueChanged];
            
            cell.accessoryView = accessory;
            
            cell.textLabel.text = @"Dynamic Media Controls";
        }
    }
    else if ((indexPath.section == 0 && _enabled.count) || (!iPad && indexPath.section == 1 && _disabled.count)) {
        NSString *ID = (indexPath.section == 0 ? _enabled[indexPath.row] : _disabled[indexPath.row]);
        
        CCBundleLoader *loader = [CCBundleLoader sharedInstance];
        
        NSString *displayName = loader.displayNames[ID];
        
        NSDictionary *replacements = loader.replacingBundles;
        
        cell.editingAccessoryType = ([replacements[ID] count] ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone);
        
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
    return (indexPath.section < 2-iPad);
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((indexPath.section == 0 && _enabled.count) || (indexPath.section == 1 && _disabled.count)) {
        CCBundleLoader *loader = [CCBundleLoader sharedInstance];
        
        NSDictionary *replacements = loader.replacingBundles;
        
        NSString *ID = (indexPath.section == 0 ? _enabled[indexPath.row] : _disabled[indexPath.row]);
        
        return ([replacements[ID] count] > 0);
    }
    else {
        return NO;
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return (!iPad && indexPath.section < 2 && ((indexPath.section == 0 && _enabled.count) || (indexPath.section == 1 && _disabled.count)));
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ((indexPath.section == 0 && _enabled.count) || (!iPad && indexPath.section == 1 && _disabled.count)) {
        CCBundleLoader *loader = [CCBundleLoader sharedInstance];
        
        NSDictionary *replacements = loader.replacingBundles;
        
        NSString *ID = (indexPath.section == 0 ? _enabled[indexPath.row] : _disabled[indexPath.row]);
        
        if ([replacements[ID] count]) {
            NSUInteger expectedSize = [replacements[ID] count]+1;
            
            NSMutableDictionary *replacementNames = [NSMutableDictionary dictionaryWithCapacity:expectedSize];
            
            NSMutableArray *orderedKeys = [NSMutableArray arrayWithCapacity:expectedSize];
            
            void (^addEntry)(NSString *key, NSString *value) = ^ (NSString *key, NSString *value) {
                [orderedKeys addObject:key];
                replacementNames[key] = value;
            };
            
            addEntry(@"de.j-gessner.ccloader.reserved.defaultStockSection", @"Default Section");
            
            for (NSBundle *r in replacements[ID]) {
                NSString *bundleIdentifier = r.bundleIdentifier;
                
                addEntry(bundleIdentifier, loader.displayNames[bundleIdentifier]);
            }

            NSString *selected = _replacements[ID];
            
            CCLoaderReplacementsViewController *replacementVC = [[CCLoaderReplacementsViewController alloc] initWithReplacements:replacementNames.copy selected:selected orderedKeys:orderedKeys.copy selectedCallback:^(NSString *selected) {
                _replacements[ID] = selected;
                
                [self syncPrefs:YES];
            }];
            
            replacementVC.title = [NSString stringWithFormat:@"%@ Section", loader.displayNames[ID]];
            
            [self.navigationController pushViewController:replacementVC animated:YES];
        }
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    if (proposedDestinationIndexPath.section > 1) {
        return sourceIndexPath;
    }
    else if ((proposedDestinationIndexPath.section == 0 && !_enabled.count) || (!iPad && proposedDestinationIndexPath.section == 1 && !_disabled.count)) {
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

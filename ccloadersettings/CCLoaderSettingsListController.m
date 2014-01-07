//
//  CCLoaderSettingsListController.m
//  CCLoader Settings
//
//  Created by Jonas Gessner on 04.01.2014.
//  Copyright (c) 2014 Jonas Gessner. All rights reserved.
//

#import "CCLoaderSettingsListController.h"

#import "CCBundleLoader.h"


@interface CCLoaderSettingsListController () <UITableViewDataSource, UITableViewDelegate> {
    NSMutableOrderedSet *_enabled;
    NSMutableOrderedSet *_disabled;
    
    NSDictionary *_displayNames;
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
        
        CCBundleLoader *loader = [CCBundleLoader sharedInstance];
        [loader loadBundles];
        
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kCCLoaderSettingsPath];
        
        _enabled = [NSMutableOrderedSet orderedSetWithArray:prefs[@"EnabledSections"]];
        _disabled = [NSMutableOrderedSet orderedSetWithArray:prefs[@"DisabledSections"]];
        
        if (!_enabled.count) {
            _enabled = [NSMutableOrderedSet orderedSetWithArray:kCCLoaderStockOrderedSections];
        }
        
        if (!_disabled) {
            _disabled = [NSMutableOrderedSet orderedSet];
        }
        
        
        NSMutableDictionary *displayNames = [kCCLoaderStockDisplayNames mutableCopy];
        
        NSMutableSet *enabledSet = (_enabled.count ? _enabled.set.mutableCopy : nil);
        NSMutableSet *disabledSet = (_disabled.count ? _disabled.set.mutableCopy : nil);
        
        for (NSBundle *bundle in loader.bundles) {
            NSString *ID = bundle.bundleIdentifier;
            
            NSString *displayName = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
            if (displayName) {
                displayNames[ID] = displayName;
            }
            
            if ([enabledSet containsObject:ID]) {
                [enabledSet removeObject:ID];
            }
            else if ([disabledSet containsObject:ID]) {
                [disabledSet removeObject:ID];
            }
            else {
                [_disabled addObject:ID];
            }
        }
        
        NSSet *stockIDs = kCCLoaderStockSections;
        
        //Remove deleted bundles:
        
        for (NSString *leftOver in enabledSet) {
            if (![stockIDs containsObject:leftOver]) {
                [_enabled removeObject:leftOver];
            }
        }
        
        for (NSString *leftOver in disabledSet) {
            if (![stockIDs containsObject:leftOver]) {
                [_disabled removeObject:leftOver];
            }
        }
        
        _displayNames = displayNames.copy;
        
        [self syncPrefs];
    }
    
    return self;
}

- (void)setTitle:(NSString *)title {
    [super setTitle:@"CCLoader"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    [self.tableView setEditing:YES];
}

- (UITableView *)tableView {
    return self.table;
}

- (void)syncPrefs {
    NSMutableDictionary *prefs = [NSMutableDictionary dictionary];
    
    if (_enabled.count) {
        prefs[@"EnabledSections"] = _enabled.array;
    }
    
    if (_disabled.count) {
        prefs[@"DisabledSections"] = _disabled.array;
    }
    
    [prefs.copy writeToFile:kCCLoaderSettingsPath atomically:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return _enabled.count;
    }
    else {
        return _disabled.count;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Enabled Sections";
    }
    else {
        return @"Disabled Sections";
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 1) {
        return [NSString stringWithFormat:@"© Jonas Gessner %@", (2014 < kYear ? [NSString stringWithFormat:@"2014-%lu", (unsigned long)kYear] : @"2014")];
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const cellID = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    
    [cell setShowsReorderControl:YES];
    
    NSString *ID = (indexPath.section == 0 ? _enabled[indexPath.row] : _disabled[indexPath.row]);
    
    NSString *displayName = _displayNames[ID];
    
    cell.textLabel.text = (displayName ? : ID);
    
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
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}



- (NSTextAlignment)tableView:(UITableView *)tableView titleAlignmentForFooterInSection:(NSInteger)section {
    return NSTextAlignmentLeft;
}
- (NSTextAlignment)tableView:(UITableView *)tableView titleAlignmentForHeaderInSection:(NSInteger)section {
    return NSTextAlignmentLeft;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}
- (NSString *)tableView:(UITableView *)tableView detailTextForHeaderInSection:(NSInteger)section {
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return CGFLOAT_MIN;
    }
    else {
        return 34.0f;
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 34.0f;
}

#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    return proposedDestinationIndexPath;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if (sourceIndexPath.section == 0) {
        NSString *sourceID = _enabled[sourceIndexPath.row];
        
        [_enabled removeObjectAtIndex:sourceIndexPath.row];
        
        if (destinationIndexPath.section == 0) {
            [_enabled insertObject:sourceID atIndex:destinationIndexPath.row];
        }
        else {
            [_disabled insertObject:sourceID atIndex:destinationIndexPath.row];
        }
    }
    else if (sourceIndexPath.section == 1) {
        NSString *sourceID = _disabled[sourceIndexPath.row];
        
        [_disabled removeObjectAtIndex:sourceIndexPath.row];
        
        if (destinationIndexPath.section == 1) {
            [_disabled insertObject:sourceID atIndex:destinationIndexPath.row];
        }
        else {
            [_enabled insertObject:sourceID atIndex:destinationIndexPath.row];
        }
    }
    
    [self syncPrefs];
    
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("de.j-gessner.ccloader.settingschanged"),  NULL, NULL, true);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

@end

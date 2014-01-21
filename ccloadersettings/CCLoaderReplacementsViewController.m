//
//  CCLoaderReplacementsViewController.m
//  CCLoader Settings
//
//  Created by Jonas Gessner on 04.01.2014.
//  Copyright (c) 2014 Jonas Gessner. All rights reserved.
//

#import "CCLoaderReplacementsViewController.h"

@interface CCLoaderReplacementsViewController () {
    NSDictionary *_replacements;
    
    NSOrderedSet *_replacementsOrdered;
    
    NSString *_selected;
    
    void (^_callback)(NSString *selected);
}

@end


@implementation CCLoaderReplacementsViewController

- (instancetype)initWithReplacements:(NSDictionary *)replacements selected:(NSString *)currentSelected orderedKeys:(NSArray *)ordered selectedCallback:(void (^)(NSString *selected))callback {
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    if (self) {
        _replacements = replacements;
        _replacementsOrdered = [NSOrderedSet orderedSetWithArray:ordered];
        _selected = currentSelected;
        _callback = callback;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _replacementsOrdered.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Select a section";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const cellID = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    
    NSString *ID = _replacementsOrdered[indexPath.row];
    
    cell.accessoryType = ([_selected isEqualToString:ID] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
    
    cell.textLabel.text = _replacements[ID];
    
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
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger oldIndex = [_replacementsOrdered indexOfObject:_selected];
    
    if (indexPath.row == oldIndex) {
        return;
    }
    
    NSString *ID = _replacementsOrdered[indexPath.row];
    
    _selected = ID;
    
    if (_callback) {
        _callback(ID);
    }
    
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:oldIndex inSection:0], indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

@end

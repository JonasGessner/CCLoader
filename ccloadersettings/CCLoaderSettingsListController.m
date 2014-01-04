//
//  CCLoaderSettingsListController.m
//  CCLoader Settings
//
//  Created by Jonas Gessner on 04.01.2014.
//  Copyright (c) 2014 Jonas Gessner. All rights reserved.
//

#import "CCLoaderSettingsListController.h"

@implementation CCLoaderSettingsListController

- (id)specifiers {
	if (_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"CCLoaderSettings" target:self];
	}
    
	return _specifiers;
}

@end

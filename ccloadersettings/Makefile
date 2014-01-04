ARCHS = armv7 armv7s arm64

TARGET = iphone:clang:latest:5.0

THEOS_BUILD_DIR = Packages

include theos/makefiles/common.mk

BUNDLE_NAME = CCLoaderSettings
CCLoaderSettings_CFLAGS = -fobjc-arc
CCLoaderSettings_FILES = CCLoaderSettingsListController.m
CCLoaderSettings_INSTALL_PATH = /Library/PreferenceBundles
CCLoaderSettings_FRAMEWORKS = Foundation UIKit
CCLoaderSettings_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/CCLoaderSettings.plist$(ECHO_END)

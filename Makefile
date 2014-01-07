ARCHS = armv7 armv7s arm64

TARGET = iphone:clang:latest:7.0

THEOS_BUILD_DIR = Packages

include theos/makefiles/common.mk

TWEAK_NAME = CCLoader
CCLoader_CFLAGS = -fobjc-arc
CCLoader_FILES = CCLoader.xm CCSectionViewController.x CCSectionView.x ccloadersettings/CCBundleLoader.m CCScrollView.m
CCLoader_FRAMEWORKS = Foundation UIKit CoreGraphics CoreFoundation

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
SUBPROJECTS += ccloadersettings
include $(THEOS_MAKE_PATH)/aggregate.mk

ARCHS = armv7 armv7s arm64

TARGET = iphone:clang:latest:7.0

THEOS_BUILD_DIR = Packages

FINALPACKAGE = 1

include theos/makefiles/common.mk

TWEAK_NAME = CCLoader
CCLoader_CFLAGS = -fno-objc-arc
CCLoader_FILES = CCLoader.xm CCSectionViewController.xm CCSectionView.x CCLoaderSettings/CCBundleLoader.m CCScrollView.m
CCLoader_FRAMEWORKS = Foundation UIKit CoreGraphics CoreFoundation
CCLoader_PRIVATE_FRAMEWORKS = SpringBoardUIServices

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += CCLoaderSettings
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 backboardd"


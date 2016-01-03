TWEAK_NAME = TouchTracking
TouchTracking_FILES = Tweak.xm TTManager.m
TouchTracking_FRAMEWORKS = Foundation, IOKit, UIKit
TARGET = iphone:clang:latest:7.0
ARCHS = armv7 armv7s arm64

include theos/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

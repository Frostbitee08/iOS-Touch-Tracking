export ARCHS = armv7 armv7s arm64
export TARGET = iphone::9.0

TWEAK_NAME = TouchTracking
TouchTracking_FILES = Tweak.xm TTManager.m preferences/TTSettingsManager.m 
TouchTracking_FRAMEWORKS = Foundation, IOKit, UIKit

include theos/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += preferences
include $(THEOS_MAKE_PATH)/aggregate.mk

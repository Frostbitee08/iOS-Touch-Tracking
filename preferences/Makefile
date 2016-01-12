include theos/makefiles/common.mk

BUNDLE_NAME = TTSettings
TTSettings_FILES = TTSettings.mm TTSettingsManager.m 
TTSettings_INSTALL_PATH = /Library/PreferenceBundles
TTSettings_FRAMEWORKS = UIKit
TTSettings_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/TTSettings.plist$(ECHO_END)

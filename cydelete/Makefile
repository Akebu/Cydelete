ARCHS = armv7 arm64

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = Cydelete
Cydelete_FILES = CydeleteRootListController.m
Cydelete_CFLAGS = -fobjc-arc
Cydelete_LDFLAGS += -Wl,-segalign,4000
Cydelete_INSTALL_PATH = /Library/PreferenceBundles
Cydelete_FRAMEWORKS = UIKit MessageUI
Cydelete_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Cydelete.plist$(ECHO_END)

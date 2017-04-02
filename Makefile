ARCHS = armv7 arm64
FINALPACKAGE=1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Cydelete9
Cydelete9_FILES = Tweak.xm
Cydelete9_LDFLAGS += -Wl,-segalign,4000
Cydelete9_FRAMEWORKS = Foundation, UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall backboardd"
SUBPROJECTS += cydelete
include $(THEOS_MAKE_PATH)/aggregate.mk

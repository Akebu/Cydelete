ARCHS = armv7 arm64
FINALPACKAGE=1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Cydelete
Cydelete_FILES = Tweak.xm
Cydelete_LDFLAGS += -Wl,-segalign,4000
Cydelete_FRAMEWORKS = Foundation, UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall backboardd"
SUBPROJECTS += cydelete
include $(THEOS_MAKE_PATH)/aggregate.mk

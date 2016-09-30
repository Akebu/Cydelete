ARCHS = arm64

include theos/makefiles/common.mk

TWEAK_NAME = Cydelete9
Cydelete9_FILES = Tweak.xm
Cydelete9_FRAMEWORKS = Foundation, UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

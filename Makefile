ARCHS = arm64 arm64e
TARGET = iphone:clang:16.5:16.0
THEOS_PACKAGE_SCHEME = rootless
INSTALL_TARGET_PROCESSES = Carbon

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = UberDriverBypass
UberDriverBypass_FILES = Tweak.xm
UberDriverBypass_FRAMEWORKS = Foundation UIKit CoreFoundation
UberDriverBypass_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Carbon || true"

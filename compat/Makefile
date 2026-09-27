ARCHS = arm64
TARGET = iphone:clang:16.5:16.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = CompatSwiftCore
CompatSwiftCore_FILES = CompatSwiftCore.s
CompatSwiftCore_LDFLAGS = -Wl,-install_name,@rpath/CompatSwiftCore.dylib -Wl,-reexport_library,$(shell find $(THEOS)/sdks -path '*/usr/lib/swift/libswiftCore.tbd' | sort -V | tail -1)

include $(THEOS_MAKE_PATH)/library.mk

ARCHS = arm64
TARGET = iphone:clang:16.5:16.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = CompatSwiftCore
CompatSwiftCore_FILES = CompatSwiftCore.s AVAudioApplicationCompat.m CompatConcurrency.swift CompatSwiftUI.swift CompatObservation.swift CompatBindable.swift

# The iOS 26-built Uber Driver binary binds several Swift overlay symbols
# directly to their parent frameworks. On iOS 16 those symbols still live
# in separate libswift* overlay dylibs. This shim is used as a proxy for
# both SwiftCore and those framework/overlay pairs.
IOS16_SDK = $(THEOS)/sdks/iPhoneOS16.5.sdk
CompatSwiftCore_LDFLAGS = \
	-Wl,-install_name,@rpath/CompatSwiftCore.dylib \
	-Wl,-reexport_library,$(IOS16_SDK)/usr/lib/swift/libswiftCore.tbd \
	-Wl,-reexport_library,$(IOS16_SDK)/usr/lib/swift/libswift_Concurrency.tbd \
	-Wl,-reexport_framework,UIKit \
	-Wl,-reexport_library,$(IOS16_SDK)/usr/lib/swift/libswiftUIKit.tbd \
	-Wl,-reexport_framework,Network \
	-Wl,-reexport_library,$(IOS16_SDK)/usr/lib/swift/libswiftNetwork.tbd \
	-Wl,-reexport_framework,PhotosUI \
	-Wl,-reexport_library,$(IOS16_SDK)/usr/lib/swift/libswiftPhotosUI.tbd \
	-Wl,-reexport_framework,AVFAudio \
	-Wl,-reexport_framework,SwiftUI

include $(THEOS_MAKE_PATH)/library.mk

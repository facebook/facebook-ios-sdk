export TARGET=iphone:latest:8.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LytroInjector
LytroInjector_FILES = Tweak.xm

LytroInjector_LDFLAGS += -F./
# Remvoe FBSDKCoreKit if the app has already integrated facebook iOS SDK
LytroInjector_FRAMEWORKS += FBSDKCoreKit FBSDKLytroKit
LytroInjector_CFLAGS += -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

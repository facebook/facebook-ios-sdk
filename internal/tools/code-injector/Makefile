export TARGET=iphone:latest:8.0
ARCHS = armv7 arm64
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = RatingHelper
RatingHelper_FILES = HRTBasicUtility.m HRTCodelessIndexer.m HRTInternalUtility.m HRTSwizzler.m HRTUtility.m HRTViewHierarchy.m

RatingHelper_CFLAGS=-fobjc-arc -Wno-unused-variable -Wno-incomplete-implementation -Wno-objc-property-implementation

include $(THEOS_MAKE_PATH)/tweak.mk

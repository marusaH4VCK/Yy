THEOS_DEVICE_IP   ?= 192.168.1.100
THEOS_DEVICE_PORT ?= 22

TARGET            := iphone:clang:latest:14.0
ARCHS             := arm64

include $(THEOS)/makefiles/common.mk

# ── Tweak ────────────────────────────────────────────────────
TWEAK_NAME        := FreeFireKeyAuth
FreeFireKeyAuth_FILES        := Tweak.xm KeyAuthUI_native.mm
FreeFireKeyAuth_FRAMEWORKS   := UIKit Foundation
FreeFireKeyAuth_CXXFLAGS     := -std=c++17 -fobjc-arc
FreeFireKeyAuth_OBJCXXFLAGS  := -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

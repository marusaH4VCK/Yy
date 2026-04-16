export THEOS_DEVICE_IP = 127.0.0.1
TARGET = iphone:clang:latest:14.0
ARCHS = arm64
DEBUG = 0
FINALPACKAGE = 1
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FreeFireKeyAuth

# ใส่ไฟล์ทั้งหมดที่ต้องการบิลด์
$(TWEAK_NAME)_FILES = Tweak.xm KeyAuthUI_native.mm
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation Security CoreGraphics QuartzCore

# --- [ จุดที่แก้ไข ] ---
# เพิ่ม -fobjc-arc เพื่อแก้ปัญหา "__weak reference"
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -std=gnu++17 -fvisibility=hidden

include $(THEOS_MAKE_PATH)/tweak.mk

after-package::
	@echo "Build Finished. Check packages folder."

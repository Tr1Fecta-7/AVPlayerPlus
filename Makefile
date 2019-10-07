FINALPACKAGE=1
export TARGET = iphone:clang:11.2:11.0
include $(THEOS)/makefiles/common.mk

ARCHS = arm64 arm64e

TWEAK_NAME = AVPlayerPlus

AVPlayerPlus_FILES = Tweak.xm
AVPlayerPlus_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "sbreload"

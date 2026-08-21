TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = Amino AltAmino Main Main-1


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = aa-xp

aa-xp_FILES = src/Redirection.x src/FirebaseKeychainFixes.x src/ServersNdcMsgSigIsNotExist.x
aa-xp_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

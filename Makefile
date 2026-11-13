TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = Amino AltAmino Main Main-1


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = aa-xp

aa-xp_FILES = src/Redirection.x src/fixes/AgoraAppIdChanger.x src/fixes/FirebaseKeychainFixes.x src/fixes/NSTextRangeIOS17.x src/fixes/ServersNdcMsgSigIsNotExist.x src/fixes/UIIncorrectColorFix.x src/fixes/UsersSearchFix.x src/features/AdKiller.x src/features/TrackKiller.x src/features/VoiceChatUserVolume.x
aa-xp_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := device/sc/k50sv1_64

# Recovery packages
PRODUCT_PACKAGES += \
    init \
    adbd \
    recovery \
    init.recovery.mt6755.rc

# fstab
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/recovery.fstab:$(TARGET_COPY_OUT_RECOVERY)/root/system/etc/recovery.fstab

# Init scripts
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/recovery/root/init.recovery.mt6755.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.mt6755.rc

# USB
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.adb.secure=0 \
    ro.secure=0 \
    persist.sys.usb.config=mtp,adb \
    persist.service.adb.enable=1 \
    persist.service.debuggable=1

# For MTK
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.hardware=mt6755

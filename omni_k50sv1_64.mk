#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit some common Omni stuff
$(call inherit-product, vendor/omni/config/common.mk)

# Inherit from k50sv1_64 device
$(call inherit-product, device/sc/k50sv1_64/device.mk)

# Device identifier
PRODUCT_DEVICE := k50sv1_64
PRODUCT_NAME := omni_k50sv1_64
PRODUCT_BRAND := SC
PRODUCT_MODEL := H9
PRODUCT_MANUFACTURER := SC
PRODUCT_RELEASE_NAME := SC H9

# MTK platform
PRODUCT_PROPERTY_OVERRIDES += \
    ro.hardware=mt6755

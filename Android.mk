#
# Copyright (C) 2026 The Android Open Source Proje
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),k50sv1_64)
include $(call all-subdir-makefiles,$(LOCAL_PATH))
endif

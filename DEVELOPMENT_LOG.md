# TWRP for SC H9 开发日志

给那些发现bug想要自己动手改device tree甚至改源码修复的人提供一下我修bug时的思路。看着玩也可以。

## 设备概述

**基础信息：**
- 型号: 松川国际 H9
- 代号: k50sv1_64
- SoC: MediaTek MT6750V
- Android版本: 8.1
- 显示: 800x1280
- **Recovery分区: 16MB**

---

## 第一阶段：基础环境搭建

### 1.1 设备树创建

使用 `twrpdtgen` 从原厂recovery提取生成设备树，创建 `device/sc/k50sv1_64/`

最初的目录结构：

```
device/sc/k50sv1_64/
├── Android.bp
├── Android.mk
├── AndroidProducts.mk
├── BoardConfig.mk
├── device.mk
├── extract-files.sh
├── omni_k50sv1_64.mk
├── README.md
├── recovery.fstab
├── setup-makefiles.sh
├── vendorsetup.sh
├── prebuilt/
│   ├── kernel
│   └── dtb.img
└── recovery/root/
    ├── init.recovery.mt6755.rc
    └── ueventd.rc
```
### 最初状态
一屏后直接黑屏重启。  

### 1.2 构建环境问题

**问题1：soong_namespace 错误**

```
error: device/sc/k50sv1_64/Android.bp:1:1: module "soong_namespace" already defined
```

**解决方案：** 删除 `Android.bp` 文件，TWRP 8.1不需要。

**问题2：Java版本不兼容**

```
error: Could not create the Java Virtual Machine.
```

**解决方案：**
```bash
sudo apt install openjdk-8-jdk
sudo update-alternatives --config java
# 选择 Java 8
```

**问题3：Python版本错误**

```
SyntaxError: Missing parentheses in call to 'print'
```

**解决方案：**
```bash
sudo apt install python2
sudo update-alternatives --config python
# 选择 Python 2
```

**问题4：缺少 libncurses.so.5**

```
error: cannot find -lncurses
```

**解决方案：**
```bash
sudo apt install libncurses5 libncurses5-dev
```

---

## 第二阶段：Recovery镜像大小优化

### 2.1 问题描述

首次编译成功后，镜像大小 **18.4MB**，超出 **16MB** 分区限制：

```
error: +recovery.img too large (18395136 > [17301504 - 270336])
```

### 2.2 解决方案

**BoardConfig.mk 优化：**
```makefile
TW_EXTRA_LANGUAGES := false
TW_EXCLUDE_BASH := true
TW_EXCLUDE_NANO := true
TW_EXCLUDE_TZDATA := true
TW_EXCLUDE_PYTHON := true
TW_INCLUDE_NTFS_3G := false
TW_EXCLUDE_SUPERSU := true
TW_EXCLUDE_TWRPAPP := true
TWRP_INCLUDE_LOGCAT := false
TARGET_USES_LOGD := false
TW_INCLUDE_CRYPTO := false
TW_INCLUDE_FBE := false
TW_INCLUDE_REPACKTOOLS := false
TW_NO_LEGACY_PROPS := true
TW_NO_BATT_PERCENT := true
TW_EXCLUDE_ENCRYPTED_BACKUPS := true
```

**移除不需要的语言文件：**

在 `bootable/recovery/gui/theme/common/languages/` 目录删除除 `en.xml` 外的所有语言文件（18个文件）。

**最终镜像大小：** ~15.6MB（在16MB限制内）

---

## 第三阶段：第一次启动失败 - 黑屏直接重启

### 3.1 问题描述

刷入编译好的recovery.img后，设备启动时**直接黑屏重启**，无法进入recovery界面。

**测试步骤：**
```bash
fastboot flash recovery out/target/product/k50sv1_64/recovery.img
fastboot reboot recovery
# 结果：黑屏，自动重启
```

### 3.2 排查过程

1. 在 `init.recovery.mt6755.rc` 中添加日志保存脚本
2. 刷入后启动，检查 `/cache` 目录
3. **结果：没有任何日志文件**，说明init脚本根本没有执行

### 3.3 原因分析

检查编译输出的ramdisk内容：

```bash
lzma -dc out/target/product/k50sv1_64/ramdisk-recovery.img | cpio -t | grep -E '^init$|^sbin/recovery$'
```

**`init` 和 `sbin/recovery` 二进制文件缺失！**

Recovery可执行文件未被编译进ramdisk。

### 3.4 解决方案

**文件：** `device.mk`

```makefile
PRODUCT_PACKAGES += \
    init \
    adbd \
    recovery
```
---

## 第四阶段：第二次启动失败 - 重启后进入fastboot

### 4.1 问题描述

添加 `PRODUCT_PACKAGES` 后重新编译，刷入后设备仍旧黑屏重启，但是却**进入了fastboot模式**。

这是进步！说明kernel加载成功了，但ramdisk执行失败。

### 4.2 原因分析（一）：Ramdisk压缩格式

检查原厂recovery和TWRP的ramdisk压缩格式：

```bash
# 原厂recovery
file H9_original_rec/ramdisk.img
# 输出: gzip compressed data

# TWRP编译输出
file out/target/product/k50sv1_64/ramdisk-recovery.img
# 输出: LZMA compressed data
```

**问题：内核可能不支持LZMA。

**解决：** 在BoardConfig.mk中禁用LZMA：

```makefile
# LZMA_RAMDISK_TARGETS := recovery
```

### 4.3 原因分析（二）：缺少挂载点目录

修改为gzip后仍然进入fastboot。对比原厂ramdisk和TWRP ramdisk的目录结构：

**原厂ramdisk有但TWRP缺少的目录：**
- `dev/`
- `proc/`
- `sys/`
- `data/`
- `cache/`
- `mnt/`
- `vendor/`
- `acct/`
- `config/`
- `oem/`
- `storage/`

这些是Linux系统必需的挂载点目录！

### 4.4 解决方案

在设备树中创建这些空目录：

```bash
cd device/sc/k50sv1_64/recovery/root/
mkdir -p dev proc sys data cache mnt vendor acct config oem storage
```

**重新编译后，设备成功进入TWRP！**

---

## 第五阶段：第三次启动失败 - SIGSEGV崩溃

### 5.1 问题描述

设备进入TWRP后立即崩溃，出现 SIGSEGV 信号，卡在黑屏。通过dmesg发现GUI初始化失败。

### 5.2 原因分析

通过分析 dmesg 日志发现：
- `/dev/fb0` 设备节点未被 ueventd 自动创建
- TWRP 的 minui 库尝试打开 `/dev/graphics/fb0` 失败
- 空指针导致 SIGSEGV 崩溃

MTK内核的 framebuffer 驱动在recovery模式下不会自动创建设备节点。

### 5.3 解决方案

**文件：** `init.recovery.mt6755.rc`

```rc
on early-init
    # Create framebuffer device node (ueventd doesn't create it automatically)
    exec -- /sbin/mknod -m 660 /dev/fb0 c 29 0

    # Create framebuffer symlink (TWRP expects /dev/graphics/fb0)
    mkdir /dev/graphics 0660 root graphics
    symlink /dev/fb0 /dev/graphics/fb0
```

**关键点：**
- 字符设备主设备号29，次设备号0
- 必须在 `early-init` 阶段创建，否则GUI初始化会失败
- 需要同时创建 `/dev/graphics/fb0` 软链接

**修复后，TWRP正常启动**

---

## 第六阶段：简体中文语言支持

### 6.1 问题描述

TWRP默认不包含中文语言包，需要添加简体中文支持。

### 6.2 解决方案

在百度上找了一圈还让我真找着了一个1.8MB的中文字体。

**目录结构：**
```
device/sc/k50sv1_64/chinese/
├── languages/
│   └── zh_CN.xml
└── fonts/
    └── DroidSansFallback.ttf
```

**BoardConfig.mk 添加：**
```makefile
TW_EXTRA_LANGUAGES := false
TW_ADDITIONAL_RES := $(DEVICE_PATH)/chinese/languages $(DEVICE_PATH)/chinese/fonts
```

---

## 第七阶段：工厂模式探索

### 7.1 背景

设备按 电源键 + 音量下键 开机会进入工厂测试模式，想要在TWRP中运行该模式。

### 7.2 工厂模式位置发现

通过分析发现，工厂模式**不是**在LK bootloader中实现，而是Linux用户空间程序：

| 项目 | 路径 |
|------|------|
| 二进制文件 | `/system/bin/factory` (ELF shared object, 64-bit ARM64) |
| 配置文件 | `/system/etc/factory.ini` (GBK编码中文) |
| 图片资源 | `/vendor/res/images/*.png` |

### 7.3 启动流程分析

```
电源+音量下 → LK检测组合键 → 设置boot_mode=4 → 启动boot分区
    → Linux init检测boot_mode=4 → 启动/system/bin/factory
```

**boot_mode状态存储于：** `/sys/class/BOOT/BOOT/boot/boot_mode`

| 值 | 模式 |
|----|------|
| 0 | 正常启动 |
| 1 | Meta模式 |
| 2 | Recovery模式 |
| 4 | 工厂模式 |

### 7.4 在TWRP中运行工厂模式的问题

**问题1：缺少 /dev/tty0**

```
failed KDSETMODE to KD_GRAPHICS on tty0: No such file or directory
```

原因：内核编译时未打开 `CONFIG_VT` (虚拟终端支持)

**问题2：boot_mode值错误**

在TWRP中，`boot_mode=2` (recovery模式)，factory检测到非4立即退出。

---

## 第八阶段：自定义内核编译尝试（失败）

### 8.1 目标

编译带有 `CONFIG_VT=y` 的自定义内核，解决 /dev/tty0 问题。

### 8.2 内核源码

使用通用MT6755内核源码：
```bash
git clone --depth=1 https://github.com/Vgdn1942/android_kernel_mt6755_3.18.119.git kernel_mt6755
```

### 8.3 配置修改

```bash
# 从设备提取配置
adb shell "su -c 'zcat /proc/config.gz'" > k50sv1_64_defconfig

# 启用VT支持
sed -i 's/# CONFIG_VT is not set/CONFIG_VT=y/' k50sv1_64_defconfig
echo "CONFIG_VT_CONSOLE=y" >> k50sv1_64_defconfig
echo "CONFIG_HW_CONSOLE=y" >> k50sv1_64_defconfig
```

### 8.4 编译错误

**错误1：缺少LCM驱动**
```
No such file or directory: drivers/misc/mediatek/lcm/ili9881c_wxga_dsi_vdo_boe/Makefile
```

**错误2：缺少图像传感器驱动**
```
No such file or directory: drivers/misc/mediatek/imgsensor/src/mt6755/gc2385mipi_raw/Makefile
```

**错误3：GCC 10+ 兼容性**
```
error: multiple definition of `yylloc'
```

**错误4：缺少设备树**
```
No rule to make target 'arch/arm64/boot/dts/k50sv1_64.dtb'
```

### 8.5 结果

❌ **编译失败** - MTK BSP源码不完整，缺少太多设备特定驱动。

---

## 第九阶段：Bind Mount方案（成功）

### 9.1 最终解决方案

使用LD_PRELOAD拦截factory对 `/dev/tty0` 和 `boot_mode` 的访问。
不需要编译内核，使用简单的设备节点创建和bind mount：

```bash
# 1. 创建假的tty0设备 (指向null设备)
mknod /dev/tty0 c 1 3
chmod 666 /dev/tty0

# 2. 设置boot_mode为factory(4)
echo "4" > /data/local/tmp/boot_mode_fake
mount --bind /data/local/tmp/boot_mode_fake /sys/class/BOOT/BOOT/boot/boot_mode

# 3. 运行factory
LD_PRELOAD=fake_tty.so /system/bin/factory
```

### 9.2 工作原理

1. **假tty0**: `mknod c 1 3` 创建指向null设备的字符设备，满足factory的open()调用
2. **bind mount**: 覆盖只读的sysfs文件，factory读取时获得"4"
3. **factory运行**: 检测到boot_mode=4，正常显示测试菜单

### 9.3 运行结果

- ✅ 显示工厂测试菜单
- ✅ 音量键导航正常
- ✅ 所有测试项可访问(不保证能用)
- ⚠️ 电源键会触发TWRP锁屏（需先停止TWRP GUI: `stop recovery`）

## 启动失败问题汇总

| 阶段 | 现象 | 原因 | 解决方案 |
|------|------|------|----------|
| 1 | 黑屏直接重启 | ramdisk缺少init和recovery二进制 | `PRODUCT_PACKAGES += recovery` |
| 2 | 重启后进入fastboot | LZMA压缩 + 缺少挂载点目录 | 改用gzip + 创建空目录 |
| 3 | SIGSEGV崩溃 | /dev/fb0未创建 | init脚本中mknod创建 |

---

## 设备树最终结构

```
device/sc/k50sv1_64/
├── Android.mk
├── AndroidProducts.mk
├── BoardConfig.mk
├── device.mk
├── DEVELOPMENT_LOG.md
├── extract-files.sh
├── fake_tty.so
├── make_recovery.sh
├── omni_k50sv1_64.mk
├── README.md
├── recovery.fstab
├── setup-makefiles.sh
├── vendorsetup.sh
├── chinese/
│   ├── languages/
│   │   └── zh_CN.xml
│   └── fonts/
│       └── DroidSansFallback.ttf
├── prebuilt/
│   ├── kernel
│   └── dtb.img
└── recovery/root/
    ├── init.recovery.mt6755.rc
    ├── init.recovery.usb.rc
    ├── ueventd.rc
    ├── dev/
    ├── proc/
    ├── sys/
    ├── data/
    ├── cache/
    ├── mnt/
    ├── vendor/
    ├── acct/
    ├── config/
    ├── oem/
    └── storage/
```
---

## 技术总结

### 成功实现

1. **TWRP基础功能** - 刷机、备份、恢复正常工作
2. **简体中文支持** - 完整的中文界面
3. **Framebuffer修复** - 通过mknod手动创建设备节点
4. **镜像大小优化** - 压缩到16MB分区限制内
5. **工厂模式在TWRP中运行** - 通过mknod + bind mount

---

2026/1/28

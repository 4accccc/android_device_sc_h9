# TeamWin Recovery Project device tree for SC H9 (k50sv1_64)
<img style="display: block; margin: 0 auto;" width="543" height="550" alt="image" src="https://github.com/user-attachments/assets/680924d1-acb7-4c9a-915e-e949308c7c0d">

| Feature                 | Specification                                                        |
| :---------------------- | :--------------------------------------------------------------------|
| CPU                     | Octa-core (8x 1.508 GHz Cortex-A53)                                  |
| Chipset                 | MediaTek MT6750V (28nm HPC+)                                         |
| GPU                     | Mali-T860 MP2                                                        |
| Memory                  | 4 GB                                                                 |
| Shipped Android Version | Android 8.1                                                          |
| Storage                 | 32 GB                                                                |
| Battery                 | 3750 mAh (non-removable)                                             |
| Display                 | 800x1280, 7.2", 210 PPI                                              |
| Rear Camera             | 5 MP, LED flash                                                      |
| Front Camera            | 2 MP                                                                 |
| Release Date            | Jun., 2022                                                           |

### "松川国际H9平板电脑点歌机"，实为安卓8.1，MT6750的杂牌平板加AOSP定制系统。

## 如何在TWRP内启动设备原生的工厂模式
```
adb push ./fake_tty.so /tmp/
adb shell
mount -o rw,remount /system
echo "4" > /data/local/tmp/boot_mode_fake
mount --bind /data/local/tmp/boot_mode_fake /sys/class/BOOT/BOOT/boot/boot_mode
mknod /dev/tty0 c 1 3
chmod 666 /dev/tty0
LD_PRELOAD=/tmp/fake_tty.so /system/bin/factory
```
## 如何构建？
最好科学上网。如果有哪步运行出错了别开issue问我，烦人。问AI就行了   
先安装依赖
~~~
sudo apt install bc bison build-essential ccache curl flex g++-multilib gcc-multilib git gnupg gperf imagemagick lib32ncurses5-dev lib32readline-dev lib32z1-dev liblz4-tool libncurses5 libncurses5-dev libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev git
~~~

[然后跟着这个教程装repo](https://mirrors.tuna.tsinghua.edu.cn/help/git-repo/)，repo装好了过后，在你的用户目录   

~~~
mkdir twrp
cd twrp
export ALLOW_MISSING_DEPENDENCIES=true
repo init -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_omni.git -b twrp-8.1
repo sync -j$(nproc)   # $(nproc)是最大线程，你也可以改小点比如4,2啥的
mkdir -p device/sc
cd device/sc
git clone https://github.com/4accccc/android_device_sc_h9.git k50sv1_64
cd ../..
source build/envsetup.sh
lunch omni_k50sv1_64-eng
mka recoveryimage
./device/sc/k50sv1_64/make_recovery.sh (可选)

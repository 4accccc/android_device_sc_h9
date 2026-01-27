# TeamWin Recovery Project device tree for SC H9 (k50sv1_64)

### "松川国际H9平板电脑点歌机"，实为安卓8.1，MT6755的杂牌平板加AOSP定制系统。

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

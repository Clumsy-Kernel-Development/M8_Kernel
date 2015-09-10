#!/bin/bash
#Define Paths
dir=~/xda/kernel/M8_Kernel
dest=~/xda/LeeDrOiD_M8_Kernel
date=$(date +%d-%m-%y)
export PATH=/home/tom/xda/kernel/toolchains/arm/linaro_4.9.4/bin:$PATH
export ARCH=arm
export SUBARCH=arm
export CROSS_COMPILE=arm-eabi-
export KBUILD_BUILD_USER=root

#Get Version Number
echo "Please enter version number: "
read version

#Ask user if they would like to clean
read -p "Would you like to clean (y/n)? " -n 1 -r
echo    
if [[ ! $REPLY =~ ^[Nn]$ ]]
then
    make clean ARCH=arm CROSS_COMPILE=arm-eabi-
fi

#Set Local Version String
rm .version
VER="-LeeDrOiD_M8_$version"
DATE_START=$(date +"%s")


make ARCH=arm CROSS_COMPILE=arm-eabi- clumsy_defconfig
str="CONFIG_LOCALVERSION=\"$VER\""
sed -i "45s/.*/$str/" .config
read -p "Would you like to see menu config (y/n)? " -n 1 -r
echo 
   
if [[ ! $REPLY =~ ^[Nn]$ ]]
then
    make ARCH=arm CROSS_COMPILE=arm-eabi- menuconfig
fi 

make -j4 ARCH=arm CROSS_COMPILE=arm-eabi-
DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo
if (( $(($DIFF / 60)) == 0 )); then
echo " Build completed in $(($DIFF % 60)) seconds."
elif (( $(($DIFF / 60)) == 1 )); then
echo " Build completed in $(($DIFF / 60)) minute and $(($DIFF % 60)) seconds."
else
echo " Build completed in $(($DIFF / 60)) minutes and $(($DIFF % 60)) seconds."
fi
echo " Finish time: $(date +"%r")"
echo

echo " Making master dtb image."

./scripts/dtbToolCM -o arch/arm/boot/dt.img -s 2048 -d "htc,project-id = <" -p ./scripts/dtc/ ./arch/arm/boot/

read -p "Would you like to make flashable zip (y/n)? " -n 1 -r
echo  
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

echo "Cleaning up old flashable kernel"
cd $dest/system/lib/modules
find . -type f -name '*.ko' -delete
rm $dest/zImage/zImage
rm $dest/dt/dt.img
rm $dest/cmdline/cmdline
cd $dest
find . -type f -name '*.zip' -delete
find . -type f -name '*.md5' -delete



cp $dir/arch/arm/boot/zImage $dest/zImage/zImage
cp $dir/arch/arm/boot/dt.img $dest/dt/dt.img
echo "console=ttyHSL0,115200,n8 androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x3b7 ehci-hcd.park=3" > $dest/cmdline/cmdline



echo "-> Making flashable zip"
cd $dir
find . -name '*ko' -exec cp '{}' $dest/system/lib/modules/ \;
#cp /home/tom/xda/kernel/Other_Modules/s2s_mod.ko $dest/system/lib/modules/s2s_mod.ko

cd $dest

str1="ini_set(\"rom_version\",          \"V$version\");"
sed -i "42s/.*/$str1/" META-INF/com/google/android/aroma-config
str2="ini_set(\"rom_date\",             \"$date\");"
sed -i "43s/.*/$str2/" META-INF/com/google/android/aroma-config
str3="ui_print(\"LeeDrOiD M8 Kernel by Clumsy, Version $version\");"
sed -i "9s/.*/$str3/" META-INF/com/google/android/updater-script

zip -r LeeDrOiD_M8_kernel_$version.zip ./

md5sum "LeeDrOiD_M8_kernel_$version.zip" > "LeeDrOiD_M8_kernel_$version.zip.md5"
chown tom:adm LeeDrOiD_M8_kernel_$version.zip
chown tom:adm LeeDrOiD_M8_kernel_$version.zip.md5
mv LeeDrOiD_M8_kernel_$version.zip ~/xda/Flashable_Kernels/LeeDrOiD_M8_kernel_$version.zip
mv LeeDrOiD_M8_kernel_$version.zip.md5 ~/xda/Flashable_Kernels/LeeDrOiD_M8_kernel_$version.zip.md5

echo "-> Done"


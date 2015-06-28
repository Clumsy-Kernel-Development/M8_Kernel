#!/bin/bash
#Define Paths
dir=~/xda/kernel/M8_Kernel
dest=~/kernel_flashable
export PATH=/usr/bin:$PATH
export ARCH=arm
export SUBARCH=arm
export CROSS_COMPILE=arm-none-eabi-
export KBUILD_BUILD_USER=root

#Get Version Number
echo "Please enter version number: "
read version

#Ask user if they would like to clean
read -p "Would you like to clean (y/n)? " -n 1 -r
echo    
if [[ ! $REPLY =~ ^[Nn]$ ]]
then
    make clean ARCH=arm CROSS_COMPILE=arm-none-eabi-
fi

#Set Local Version String
rm .version
VER="-LeeDrOiD_M8_$version"
DATE_START=$(date +"%s")


make ARCH=arm CROSS_COMPILE=arm-none-eabi- clumsy_defconfig
str="CONFIG_LOCALVERSION=\"$VER\""
sed -i "45s/.*/$str/" .config
read -p "Would you like to see menu config (y/n)? " -n 1 -r
echo 
   
if [[ ! $REPLY =~ ^[Nn]$ ]]
then
    make ARCH=arm CROSS_COMPILE=arm-none-eabi- menuconfig
fi 

make -j4 ARCH=arm CROSS_COMPILE=arm-none-eabi-
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

#./scripts/dtbTool -s 2048 -o arch/arm/boot/dt.img -p scripts/dtc/ arch/arm/boot/
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
cd $dest
find . -type f -name '*.zip' -delete
find . -type f -name '*.img' -delete


cd ~/AIK-Linux
echo "-> Making boot image"
cp bootimg/boot.img boot.img

bash unpackimg.sh boot.img > ~/null

cp $dir/arch/arm/boot/zImage ~/AIK-Linux/split_img/boot.img-zImage
cp $dir/arch/arm/boot/dt.img ~/AIK-Linux/split_img/boot.img-dtb


bash repackimg.sh > ~/null

cp image-new.img $dest/boot.img


echo "-> Making flashable zip"
cd $dir
find . -name '*ko' -exec cp '{}' $dest/system/lib/modules/ \;
cp /home/tom/xda/kernel/Other_Modules/s2s_mod.ko $dest/system/lib/modules/s2s_mod.ko
sleep 5s

cd $dest


zip -r LeeDrOiD_M8_kernel_$version.zip ./
chown tom:adm LeeDrOiD_M8_kernel_$version.zip

bash ~/AIK-Linux/cleanup.sh > ~/null
echo "-> Done"


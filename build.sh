#!/bin/bash
#Define Paths
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

dtbTool=~/toolchains/dtbToolCM
date=$(date +%d-%m-%y)
rm -r $dest
export PATH=~/toolchains/arm/linaro_5.2/bin:$PATH
export ARCH=arm
export SUBARCH=arm
export CROSS_COMPILE=arm-eabi-
export KBUILD_BUILD_USER=root

#Get Version Number
echo "Please enter version number: "
read version

echo "Please enter device (m8, m8wl, m8whl, m8dug): "
read device

#Ask user if they would like to clean
read -p "Would you like to clean (y/n)? " -n 1 -r
echo    
if [[ ! $REPLY =~ ^[Nn]$ ]]
then
    make clean 
    make mrproper
    rm .config
fi

#Set Local Version String
rm .version
rm arch/arm/boot/*.dtb
VER="-clumsy_$device_$version"
DATE_START=$(date +"%s")

if [ "$device" = "m8" ]
then
	echo "######### Making M8 Device kernel ###########"
	make clumsy_defconfig
	dest=~/xda/MM_M8_Kernel/international
fi
if [ "$device" = "m8wl" ]
then
	echo "######### Making M8WL Device kernel ###########"
	make clumsy_m8wl_defconfig
	dest=~/xda/MM_M8_Kernel/verizon
fi
if [ "$device" = "m8whl" ]
then
	echo "######### Making M8WHL Device kernel ###########"
	make clumsy_m8whl_defconfig
	dest=~/xda/MM_M8_Kernel/sprint
fi
if [ "$device" = "m8dug" ]
then
	echo "######### Making M8DUG Device kernel ###########"
	make clumsy_m8dug_defconfig
	dest=~/xda/MM_M8_Kernel/dual
fi
rm -r $dest > /dev/null

str="CONFIG_LOCALVERSION=\"$VER\""
sed -i "45s/.*/$str/" .config
read -p "Would you like to see menu config (y/n)? " -n 1 -r
echo 
   
if [[ ! $REPLY =~ ^[Nn]$ ]]
then
    make menuconfig
fi 

make -j4 
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
mkdir -p $dest

echo "Making dt.img"
$dtbTool -o arch/arm/boot/dt.img -s 2048 -d "htc,project-id = <" -p scripts/dtc/ arch/arm/boot/ > /dev/null

mkdir -p $dest/modules/
mkdir -p $dest/dt/
mkdir -p $dest/zImage/
find . -name '*ko' -exec cp '{}' $dest/modules/ \;
cp arch/arm/boot/zImage $dest/zImage/.
cp arch/arm/boot/dt.img $dest/dt/.


echo "-> Done"


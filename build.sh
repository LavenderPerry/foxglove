#!/bin/sh -e

#
# Build script for Foxglove OS
# For now just tries to do all the commands I ran to get it working,
# and serves as documentation
# as well as a recovery process in case I somehow lose all my progress.
# Eventually I might have a proper Makefile or something for all this,
# or use a tool like buildroot or Yocto.
#

#
# 0. Make sure the person running this script knows what they are doing...
#

# Big scary warning
printf "\e[1m\e[31m!! PROBABLY DON'T RUN THIS SCRIPT !!\e[0m\n"
cat << ENDWARNING

It's more documentation of what I did than an actual working build automation.

The only scenario where you should be using this is if you are me
and you somehow lost all your progress and want to restore it quickly.

The intended use of this script is to read through it to understand the process.

This script also does not respect anything about your environment.
There is no configuration, your environment variables may be overwritten, etc.
It will at least try to restore things to how they were before running though.

The script also assumes all git submodules are properly initialized,
and your working directory is the root of this repository,
so make sure both of those are true before running this script.

I cannot make any guarantees that this will work at all,
or that it's even safe to run on your computer.

ENDWARNING

# Ask for consent
printf 'Type "yes" to run the script anyways, anything else to exit: '
read -r input
[ "$input" = "yes" ]

# Ask again (this one might be a bit annoying...)
printf "\e[3mAre you SURE?\e[0m: "
read -r input
[ "$input" = "yes" ]

# Exit instructions
echo "Press Ctrl+C at any time to stop this script."
sleep 3

#
# 1. Setup environment
#

# Script-wide variables
privesc=sudo
outname=foxglove-$(date -u +%Y%m%d)
repodir=$PWD
buildir=$repodir/build
rootdir=$buildir/$outname
bootdir=$rootdir/boot

# Make directories for rootfs
mkdir -p "$bootdir"

# Set the number of threads make will use.
#
# Here, it is set to the amount of CPU cores the machine has.
# You could also try modifying this by adding 1, subtracting 2,
# or multiplying by 1.5 (round down to nearest whole number).
# There's not really a consensus on what gives the best performance,
# other than if you have multiple cores, it should be greater than 1.
#
# However, some make tasks may not be designed to run concurrently.
# In this script, I may override the value set here in those cases,
# but if a make task isn't executing things in the right order,
# try running it with jobs set to 1.
prev_MAKEFLAGS=$MAKEFLAGS
MAKEFLAGS="--jobs=$(nproc)"
export MAKEFLAGS

#
# 2. Build and install the Linux kernel
#
# Resources:
# https://www.raspberrypi.com/documentation/computers/linux_kernel.html
# https://www.kernel.org/doc/html/latest/admin-guide/README.html
#

cd linux

# Save original values of the variables exported here, to restore later
prev_ARCH=$ARCH
prev_CROSS_COMPILE=$CROSS_COMPILE

# Define variables used in the build
# Probably change these if something goes wrong here, they are specific to a:
#
# cross compiled kernel build
#
# for the ARM EABI
# (intended to run on ARMv6Z, the Raspberry Pi Zero W, the Foxglove hardware)
#
# on an x86_64 Arch Linux machine
# (yes "i use arch btw" but it's actually relevant to the CROSS_COMPILE variable
#  because I'm using the toolchain from the Arch repos)
configtask=bcmrpi_defconfig
kernel=kernel
image=zImage
export ARCH=arm
export CROSS_COMPILE=arm-none-eabi-

# Clean the source tree.
# Might not be needed, but still recommended before every kernel build
make mrproper

# Configure the build
make $configtask
patch .config < ../linux-.config.patch

# Compile the kernel (this one takes a while...)
make $image modules dtbs

# Install the kernel
make "INSTALL_MOD_PATH=$rootdir" modules_install
cp arch/$ARCH/boot/$image "$bootdir/$kernel.img"
cp arch/$ARCH/boot/dts/broadcom/*.dtb "$bootdir"
cp arch/$ARCH/boot/dts/overlays/*.dtb* "$bootdir/overlays"
cp arch/$ARCH/boot/dts/overlays/README "$bootdir/overlays"

#
# 3. Add proprietary firmware
#
# At some point I could try unofficial open source firmware but for now,
# download the binaries of the official firmware
#

cd "$bootdir"

# Download the firmware binaries
repo="raspberrypi/firmware"
commit="effea745e592ec8a97fc54093a5673a7e6e515c9"
for binary in bootcode.bin fixup.dat start.elf; do
    curl https://raw.githubusercontent.com/$repo/$commit/boot/$binary -o $binary
done

# Verify the downloaded files, exits on failure
sha256sum -c "$repodir/proprietary-firmware-hashes.sha256"

#
# 4. Create compressed rootfs and disk image
#
# Much of this part uses Void Linux's mkimage and mkrootfs scripts as reference:
# https://github.com/void-linux/void-mklive/blob/906652a/mkimage.sh
# https://github.com/void-linux/void-mklive/blob/906652a/mkrootfs.sh
#

cd "$buildir"

# Create the compressed rootfs
tarfile="$outname.tar.xz"
tar cp --posix \
    --group=root --owner=root \
    --xattrs --xattrs-include='*' \
    -C "$rootdir" . | xz -T0 -9 > "$tarfile"

# Sizes in disk sectors
reserve=2048
bootsize=32768 # 16mb, but may want to increase later... recommended is 256mb
read -r rootsize _ <<ENDCMD
$(du -B 512 -s --exclude=boot "$rootdir")
ENDCMD
fullsize=$((reserve + bootsize + rootsize))

# Create the image file and mount point to edit it
imagedir=$(mktemp -d)
imageboot=$imagedir/boot
imagefile=$outname.img
truncate -s $((fullsize * 512)) "$imagefile"

# Create the partitions
sfdisk "$imagefile" <<ENDINPUT
label: dos
$reserve,$bootsize,b,*
,+,L
ENDINPUT

# Create the file systems
loopdev=$($privesc losetup --show --find --partscan "$imagefile")
p1="${loopdev}p1"
p2="${loopdev}p2"
$privesc mkfs.vfat -I -F16 "$p1"
$privesc mkfs.ext4 -O ^has_journal "$p2"

# Mount the partitions
$privesc mount "$p2" "$imagedir"
$privesc mkdir -p "$imageboot"
$privesc mount "$p1" "$imageboot"

# Extract the compressed rootfs onto the image
$privesc tar xfp "$tarfile" --xattrs --xattrs-include='*' -C "$imagedir"

# Unmount directories and deconfigure loop device
$privesc umount -R "$imagedir"
$privesc losetup -d "$loopdev"
rmdir "$imagedir" || echo "WARNING: $imagedir not empty after unmount"

# Compress the image
xz -T0 -9 "$imagefile"

#
# 5. Cleanup
#

cd "$repodir"

# Restore environment to whatever it was before this script
ARCH=$prev_ARCH
export ARCH
CROSS_COMPILE=$prev_CROSS_COMPILE
export CROSS_COMPILE
MAKEFLAGS=$prev_MAKEFLAGS
export MAKEFLAGS

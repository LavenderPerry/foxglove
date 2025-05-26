#!/bin/sh -e

#
# Build script for the rootfs
# For now just tries to do all the commands I ran to get it working,
# and serves as documentation
# as well as a recovery process in case I somehow lose all my progress.
# Eventually I will have a proper Makefile or something for all this,
# or use a tool like buildroot or Yocto.
# The only reason I'm doing this all manually now instead of using one of those
# tools is to improve my own understanding of the process.
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

# Specify and make output directories
# Just boot for now, until I get more stuff built
bootdir=out/boot
mkdir -p $bootdir

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

# Set the working directory to the repository containing
# Raspberry Pi's fork of the Linux kernel (assuming submodules are initialized).
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
installdir=../$bootdir
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
make INSTALL_MOD_PATH=$installdir modules_install
cp arch/$ARCH/boot/$image $installdir/$kernel.img
cp arch/$ARCH/boot/dts/broadcom/*.dtb $installdir
cp arch/$ARCH/boot/dts/overlays/*.dtb* $installdir/overlays
cp arch/$ARCH/boot/dts/overlays/README $installdir/overlays

# Restore environment to how it was before building/installing the kernel
cd ..
ARCH=$prev_ARCH
export ARCH
CROSS_COMPILE=$prev_CROSS_COMPILE
export CROSS_COMPILE

#
# 3. Add proprietary firmware
#
# At some point I could try unofficial open source firmware but for now,
# download the binaries of the official firmware
#

# Download the firmware binaries
repo="raspberrypi/firmware"
commit="effea745e592ec8a97fc54093a5673a7e6e515c9"
for binary in bootcode.bin fixup.dat start.elf; do
    curl https://github.com/$repo/raw/$commit/boot/$binary -o $bootdir/$binary
done

# Verify the downloaded files, exits on failure
sha256sum -c proprietary-firmware-hashes.sha256

#
# 4. Cleanup
#

# Restore MAKEFLAGS to whatever it was before this script
MAKEFLAGS=$prev_MAKEFLAGS
export MAKEFLAGS

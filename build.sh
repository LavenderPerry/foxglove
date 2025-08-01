#!/bin/sh -e

######################################
# Foxglove OS build script           #
# Builds the entire operating system #
######################################

echo "This script does a lot! You should read through it before running it."
printf 'Type "yes" to run the script anyways, anything else to exit: '
read -r input
[ "$input" = "yes" ]

echo "Press Ctrl+C at any time to stop this script."
sleep 3

#
# Set all environment variables for the rest of the build process.
# Feel free to modify these.
# If you don't intend to modify the directory variables,
# run this from the repo root.
#

arch=arm
ccarch=${arch}v6kz
target=$ccarch-linux-musleabihf
privesc=sudo
threads=$(nproc)
outname=foxglove-$(date -u +%Y%m%d)
repodir=$PWD
rootdir=$repodir/sysroot
buildir=$repodir/build
srcsdir=$buildir/sources
crosdir=$buildir/toolchain
prevpath=$PATH
PATH=$crosdir/bin:$PATH

#
# Get the sources that are involved in the operating system,
# including the kernel, build tools, etc.
# Also get the firmware binaries.
#

get() {
    curl -o "$1.tar.$3" "$4"
    echo "$1-$2"
}

ghget() {
    get "${1##*/}" "${2##*/}" gz "https://codeload.github.com/$1/tar.gz/$2"
}

mkdir -p "$srcsdir"
cd "$srcsdir"

# Source code
mussel="$(ghget firasuke/mussel 95dec40aee2077aa703b7abc7372ba4d34abb889)"
linux="$(ghget raspberrypi/linux refs/tags/stable_20250428)"
sdl="$(ghget libsdl-org/SDL refs/tags/release-3.2.18)"
mesa="$(get mesa 25.1.6 xz https://archive.mesa3d.org/mesa-25.1.6.tar.xz)"
openal="$(ghget kcat/openal-soft refs/tags/1.24.3)"
lua="$(get lua 5.4.8 gz https://www.lua.org/ftp/lua-5.4.8.tar.gz)"
cffilua="$(ghget q66/cffi-lua refs/tags/v0.2.3)"
freetype="$(get freetype 2.13.3 gz https://download.savannah.gnu.org/releases/freetype/freetype-2.13.3.tar.gz)"
harfbuzz="$(ghget harfbuzz/harfbuzz refs/tags/11.2.1)"
modplug="$(get libmodplug 0.8.9.0 gz https://psychz.dl.sourceforge.net/project/modplug-xmms/libmodplug/0.8.9.0/libmodplug-0.8.9.0.tar.gz)"
ogg="$(ghget xiph/ogg refs/tags/v1.3.6)"
vorbis="$(ghget xiph/vorbis refs/tags/v1.3.7)"
theora="$(ghget xiph/theora refs/tags/v1.2.0)"
love="$(ghget love2d/love 201dc2ae4602737ba1999701d6f7abb580ab323b)"

# Proprietary firmware binaries
repo="raspberrypi/firmware"
commit="effea745e592ec8a97fc54093a5673a7e6e515c9"
for bin in bootcode.bin fixup.dat start.elf; do
    curl -o $bin https://raw.githubusercontent.com/$repo/$commit/boot/$bin
done

# Check file validity (exits if any files are invalid)
sha256sum -c "$repodir/sources.sha256"

# Extract sources
for src in *.tar.*; do tar xf "$src"; done

#
# Make the cross compiler for building the rest of the operating system.
# Currently, it uses the mussel project.
# Eventually, I may write my own script based on mussel if needed.
#

cd "$buildir"

"$srcsdir/$mussel/check"
"$srcsdir/$mussel/mussel" "$ccarch" -l -p

#
# Build the Linux kernel.
# Resources:
#     https://www.raspberrypi.com/documentation/computers/linux_kernel.html
#     https://www.kernel.org/doc/html/latest/admin-guide/README.html
#

buildmk() { make -j"$threads" ARCH="$arch" CROSS_COMPILE="$target-" "$@"; }

cd "$srcsdir/$linux"

# Clean the source tree.
# Might not be needed, but still recommended before every kernel build
make mrproper

# Configure the build
buildmk bcmrpi_defconfig
patch .config < "$repodir"/linux-.config.patch

# Compile the kernel (takes a while...)
buildmk zImage modules dtbs

#
# Make the disk image for the operating system files to be installed to.
# Much of this uses Void Linux's live image scripts for reference:
#     https://github.com/void-linux/void-mklive
#

cd "$buildir"

# Sizes in disk sectors
reserve=2048 # 1mb
bootsize=524288 # 256mb
rootsize=1570816 # 767mb
fullsize=$((reserve + bootsize + rootsize)) # 1gb

# Create the image file
imagefile=$outname.img
truncate -s $((fullsize * 512)) "$imagefile"

# Create the partitions
# The first one is for boot files, the second is for the rest of the OS
sfdisk "$imagefile" <<ENDINPUT
label: dos
start=$reserve, size=$bootsize, type=b, bootable
start=        , size=+        , type=L
ENDINPUT

# Configure the loopback device to access the partitions
loopdev=$($privesc losetup --show --find --partscan "$imagefile")
p1="${loopdev}p1"
p2="${loopdev}p2"

# Make the filesystems
$privesc mkfs.vfat -I -F16 "$p1"
$privesc mkfs.ext4 -O ^has_journal "$p2"

# Create a temporary directory for mounting the partitions
imagedir=$(mktemp -d)
imageboot="$imagedir/boot"

# Mount the image partitions
$privesc mount "$p2" "$imagedir"
$privesc mkdir -p "$imageboot"
$privesc mount "$p1" "$imageboot"

# Copy all the root files over
$privesc cp -r "$rootdir" "$imagedir"

# Add the Linux kernel files
$privesc make -C "$srcsdir/$linux" "INSTALL_MOD_PATH=$imagedir" modules_install
$privesc cp "$srcsdir/$linux"/arch/arm/boot/zImage "$imageboot"
$privesc cp "$srcsdir/$linux"/arch/arm/boot/dts/broadcom/*.dtb "$imageboot"
$privesc cp "$srcsdir/$linux"/arch/arm/boot/dts/overlays/*.dtb* \
    "$imageboot/overlays"
$privesc cp "$srcsdir/$linux"/arch/arm/boot/dts/overlays/README \
    "$imageboot/overlays"

# Copy the firmware
$privesc cp "$srcsdir/bootcode.bin" "$imageboot"
$privesc cp "$srcsdir/fixup.dat" "$imageboot"
$privesc cp "$srcsdir/start.elf" "$imageboot"

# Create a tarfile of the rootfs
tarfile="$outname.tar"
tar cp --posix --group=root --owner=root --xattrs --xattrs-include='*' \
    --file "$tarfile" "$imagedir"

# Unmount image partitions and deconfigure loop device
$privesc umount -R "$imagedir"
$privesc losetup -d "$loopdev"
rmdir "$imagedir" || echo "WARNING: $imagedir not empty after unmount"

# Compress the tarfile and imagefile
xz -T0 -9 "$tarfile" "$imagefile"

cat <<EOF
Outputs:
    $buildir/$imagefile.xz
    $buildir/$tarfile.xz
EOF

#
# Restore previous environment
#

PATH=$prevpath
cd "$repodir"

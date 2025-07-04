# Foxglove OS

The operating system for the Foxglove handheld video game system.

Uses the Linux kernel, made for Raspberry Pi.

## Building

Very work in progress still, but if you really want to build this,
inspect `build.sh` (but don't just blindly run it!).

## Running

This hasn't even begun yet, I need to make the OS usable first.

It is intended to run on a Raspberry Pi Zero W,
so use a virtual machine that emulates it (or real hardware if you want).

## Files

* `build.sh`: The build script, outputs an image and rootfs.
* `root/`: All the files that are used unmodified in the final image/rootfs.
* `linux-.config.patch`: The difference between the Linux kernel's default
generated build configuration and Foxglove's kernel build configuration.
It is very small right now, but will grow as development continues.

## License

This repository is licensed under the zlib license, viewable at `LICENSE.txt`.

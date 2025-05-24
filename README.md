# Foxglove OS

The operating system for the Foxglove handheld video game system.

Uses the Linux kernel, made for Raspberry Pi.

## Cloning

This repository uses git submodules,
so you will have to obtain the submodules before using it.
The commands to do so look something like this:
```sh
git clone https://codeberg.org/elle/foxglove-os.git
# or git clone https://github.com/LavenderPerry/foxglove-os.git

cd foxglove-os

git submodule update --init --recursive
# some submodules are quite large,
# so you may specify --depth=1 (or another number) to download less
```

## Building

Currently, the only thing working so far is compiling the kernel.

I haven't even established a proper build system set.

But if you really want to build this, inspect `build.sh`
(but don't just blindly run it!).

## Running

This hasn't even begun yet, I need to make the OS usable first.

It is intended to run on a Raspberry Pi Zero W,
so use a virtual machine that emulates it (or real hardware if you want).

## Files

* `linux/`: Raspberry Pi's fork of the Linux kernel source code
(as a git submodule).

* `linux-.config.patch`: The difference between the Linux kernel's default
generated build configuration and Foxglove's kernel build configuration.
It is very small right now, but will grow as development continues.

* `build.sh`: An attempt at a build system.
It is meant to serve as documentation until I implement something more robust.

## License

This repository is licensed under the zlib license, viewable at `LICENSE.txt`.
Submodules included within this repository have their own licenses,
usually viewable at the root of their repositories/directories.

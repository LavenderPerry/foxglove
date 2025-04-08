# Foxglove Launcher

This is a game launcher for an in-progress handheld game console
currently named Foxglove.

It runs on the [LÖVE](https://love2d.org) framework and can launch LÖVE games.

This may be changed to / integrated in a custom version of LÖVE depending on how
much of LÖVE needs to be reimplemented in a regular LÖVE game version.

## Building

In progress, for now just run
```sh
love .
```
in the directory with the launcher to run it.

## Usage

Games are placed in this launcher's save directory,
in a directory called "Games".

The location of the games directory is platform specific,
on Linux it is `~/.local/share/love/foxglove/Games`.

Games may be any format that LÖVE can extract
(.love files, fused Windows .exe files, anything else that has ZIP archive data)
or an uncompressed directory containing the game.

Icons for the games go in a directory called "Icons", at the same place as the
games directory. So on Linux that would be `~/.local/share/love/foxglove/Icons`.

The file name for the icons should be in the format `{game title}.png`. The game
title is set in conf.lua, with the key "title"
(see the [LÖVE Wiki](https://www.love2d.org/wiki/Config_Files)). If the title is
not set, it will be the filename of the game itself. For best results, it should
be a size that cleanly scales to 64x64 (64x64, 32x32, 16x16, 8x8, etc).

## Credits / Assets Used

* Font: [m6x11](https://managore.itch.io/m6x11) by Daniel Linssen

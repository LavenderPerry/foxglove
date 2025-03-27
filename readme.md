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

## Credits / Assets Used

* Font: [m6x11](https://managore.itch.io/m6x11) by Daniel Linssen

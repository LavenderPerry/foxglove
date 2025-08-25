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

The file name for the icons should be in the format `{game}.png`.
In the curly brackets, put the game's filename without the extension,
if there is one. For best results, it should
be a size that cleanly scales to 128x128 (128x128, 64x64, 32x32, 16x16, etc).

To mod a game, the mods go in a similar place as icons,
with the path being `Mods/{game}/active`. Again, on Linux,
`~/.local/share/love/foxglove/Mods/{game}/active`.
Each mod is a directory or zip file with Lua files that take the contents of a
file and manipulate ("patch") them. An example of such is as follows:
```lua
local M = {
    -- File may be optionally set to the filename to patch
    -- If not specified, it will be the name of the Lua file you are writing in
    -- This is useful for patching non-Lua files, as you must have the `.lua` extension on files specifying patches
    -- For example, if you have a file at `foo/bar.lua` but actually want to change `foo/bar.png`,
    -- you can set `file` as seen below:
    file = "bar.png"
}

-- This is the function that patches the file
-- It should return a string with the new file contents
-- `contents` is a string with the current contents of the file
-- `filepath` is the path to the file being patched
-- `patched` is a boolean indicating if the file was patched by another mod
function M.patch(contents, filepath, patched)
    -- `love.patch.apply` is a Foxglove specific function
    -- It makes it easier to edit these files (see below for usage)
    return love.patch.apply(contents, {
        -- There are a few options to specify where to apply your patch
        -- You do not need to specify all of these, most likely you only need one
        -- However, they will all be present below to show how to use them

        -- `prepend` puts your patch at the beginning of the file if set to true
        -- `append` puts your patch at the end of the file if set to true
        prepend = true,
        append = true,

        -- `before` specifies a line to put your patch before
        -- `after` specifies a line to put your patch after
        -- When searching for these lines, leading and trailing whitespace is removed
        before = "foo = bar()",
        after = "if baz%[%d%] then",
        
        -- The options below modify the behavior for applying a patch,
        -- specifically in regards to how the `before` and `after` options work

        -- As you can see above, `after` uses a Lua pattern
        -- (see https://www.lua.org/pil/20.1.html & https://www.lua.org/pil/20.2.html for info on patterns)
        -- In order to roughly match a pattern instead of comparing a line exactly for before/after,
        -- set pattern as shown below. If you want the line to match exactly instead, you don't need to do this
        pattern = true,

        -- By default, the line you are searching for in `before` or `after`
        -- will not be overwritten. Both your injected code and the original line will be present in the result.
        -- If you want to remove the line you searched for, set `overwrite` as shown below
        overwrite = true,

        -- The options below specify the specific data to inject into the file

        -- `payload` is the text to place into the file
        -- It can either be a string or a sequence of strings
        -- If it is a sequence of strings, each string will be joined together by newlines
        payload = { "foo()", 'require("bar")' },
        -- or:
        -- payload = [[
        -- foo()
        -- require("bar")
        -- ]],

        -- `source` is a file or multiple files to read from to get the data to inject
        -- The paths should be relative to the mod directory (or root of the archive)
        -- It can either be a string specifying a single file, or a sequence specifying multiple files
        source = "foo.txt"
        -- or for multiple files:
        -- source = { "foo.txt", "bar.lua", "baz.png" }
    })

    -- This function may contain any code you would like, it does not have to use `love.patch.apply`
    -- It just must return a string representing the new file contents
end
```
The directory name does not currently matter, but may be used to refer to your
mod in the future.

-- TODO: describe mod structure

## Credits / Assets Used

* Font: [m6x11](https://managore.itch.io/m6x11) by Daniel Linssen

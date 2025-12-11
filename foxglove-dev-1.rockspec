package = "foxglove"
version = "dev-1"
source = {
   url = "git+ssh://forgejo@industryplant.club/lavender/foxglove.git"
}
description = {
   detailed = [[
The operating system and application
for the Foxglove handheld video game system.]],
   homepage = "*** please enter a project homepage ***",
   license = "*** please specify a license ***"
}
dependencies = {
    "luaexpat >= 1.5.2"
}
build = {
   type = "builtin",
   modules = {
      ["launcher.conf"] = "launcher/conf.lua",
      ["launcher.lib.drawing"] = "launcher/lib/drawing.lua",
      ["launcher.lib.game"] = "launcher/lib/game.lua",
      ["launcher.lib.installer"] = "launcher/lib/installer.lua",
      ["launcher.lib.launcher"] = "launcher/lib/launcher.lua",
      ["launcher.lib.path"] = "launcher/lib/path.lua",
      ["launcher.main"] = "launcher/main.lua"
   }
}

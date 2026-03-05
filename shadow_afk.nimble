# Package

version       = "0.1.0"
author        = "Jay Walker"
description   = "An executable to keep Shadow.Tech remote gaming PC's from logging out when AFK."
license       = "MIT"
srcDir        = "src"
bin           = @["shadow_afk"]


# Dependencies

requires "nim >= 2.2.2"
requires "winim >= 3.0.0"
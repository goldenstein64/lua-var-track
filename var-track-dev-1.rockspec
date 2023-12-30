rockspec_format = "3.0"
package = "var-track"
version = "dev-1"
source = {
   url = "https://github.com/goldenstein64/lua-var-track"
}
description = {
   homepage = "https://github.com/goldenstein64/lua-var-track",
   license = "MIT",
   summary = "A small meta-module for tracking the state of variables in a Lua-ish program",
   detailed = [[
      This module offers a minimal API for tracking variables in a program by
      calling its methods in the order variables are used in the program.
      Diagnostics are also generated.
   ]]
}
test_dependencies = {
   "busted ~> 2.2",
   "moonscript ~> 0.5",
}
test = {
   type = 'busted'
}
dependencies = {
   "lua >= 5.1"
}
build = {
   type = "builtin",
   modules = {
      ["var-track"] = "var-track.lua"
   },
   copy_directories = { "types" }
}

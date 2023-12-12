rockspec_format = "3.0"
package = "var-track"
version = "dev-1"
source = {
   url = "*** please add URL for source tarball, zip or repository here ***"
}
description = {
   homepage = "*** please enter a project homepage ***",
   license = "*** please specify a license ***"
}
test_dependencies = {
   "busted ~> 2.2",
   "moonscript ~> 0.5",
}
test = {
   type = 'busted'
}
dependencies = {
   "lua ~> 5.1"
}
build = {
   type = "builtin",
   modules = {}
}

---@meta

---holds all data pertaining to the usage of a variable
---@class var-track.var
---the variable's name
---@field name string
---the tracker this variable belongs to. `nil` means it's a global.
---@field owner var-track.VarTrack?
---whether the variable is a constant
---@field constant boolean
---where the variable was declared
---@field declared any
---where the variable was defined
---@field defined any[]
---where the variable was referenced
---@field referenced any[]
---the variable this is shadowing if any
---@field shadow var-track.var?

---a local was declared but never referenced
---@class var-track.diagnostic.unused_local
---@field type "unused_local"
---@field var var-track.var

---a local was re-declared over another local
---@class var-track.diagnostic.shadowed_local
---@field type "shadowed_local"
---@field var var-track.var

---a *new* global was defined
---@class var-track.diagnostic.defined_global
---@field type "defined_global"
---@field var var-track.var

---a constant was defined more than once
---@class var-track.diagnostic.redefined_constant
---@field type "redefined_constant"
---@field data any
---@field var var-track.var

---a global was referenced but never defined
---@class var-track.diagnostic.unknown_global
---@field type "unknown_global"
---@field var var-track.var

---a local was referenced but never defined
---@class var-track.diagnostic.uninitialized_local
---@field type "uninitialized_local"
---@field data any
---@field var var-track.var

---a diagnostic emission. It typically represents a problem with how a variable
---was used.
---@alias var-track.diagnostic
---| var-track.diagnostic.unused_local
---| var-track.diagnostic.shadowed_local
---| var-track.diagnostic.defined_global
---| var-track.diagnostic.redefined_constant
---| var-track.diagnostic.unknown_global
---| var-track.diagnostic.uninitialized_local

---a class that implements variable tracking. Instantiating this means a
---program has begun.
---
---```lua
----- beginning of program
---local tracker = VarTrack(globals)
---```
---
---Examples:
---
---```lua
-----[[
---local foo = 5
---
---foo = foo * 10
---
---print(foo)
---]]
---
---local globals = {}
---for name in pairs(_G) do
---  globals[name] = { data... }
---end
---local tracker = VarTrack(globals)
---
----- local foo = 5
---tracker:declare("foo", { data... })
---tracker:define("foo", { data... })
---
----- foo = foo * 10
---tracker:reference("foo", { data... })
---tracker:define("foo", { data... })
---
----- print(foo)
---tracker:reference("print", { data... })
---tracker:reference("foo", { data... })
---```
---@class var-track.VarTrack.Class
---@overload fun(globals?: { [string]: any }): var-track.VarTrack
local VarTrackClass = {}

---a variable tracker
---@class var-track.VarTrack
---@field declared { [string]: var-track.var }
---@field diagnostics var-track.diagnostic[]
---@field parent var-track.VarTrack?
local VarTrack = {}

---declares a variable `name`
---
---```lua
----- local foo
---tracker:declare('foo')
---```
---
---The `data` argument is used to store extra information about the variable's
---declaration.
---@param name string
---@param data? any -- defaults to `true`
---@return var-track.var
function VarTrack:declare(name, data) end

---defines a variable `name`
---
---```lua
----- foo = 5
---tracker:define('foo')
---```
---
---The `data` argument is used to store extra information about the variable's
---definition.
---@param name string
---@param data? any -- defaults to `true`
function VarTrack:define(name, data) end

---references a variable `name`
---
---```lua
----- print(foo)
---tracker:reference('print')
---tracker:reference('foo')
---```
---
---The `data` argument is used to store extra information about the variable's
---reference.
---@param name string
---@param data? any -- defaults to `true`
function VarTrack:reference(name, data) end

---ends this variable tracker's scope
---
---```lua
-----[[
---  ...
---end
---]]
---tracker:done()
---```
---@return var-track.diagnostic[] diagnostics
function VarTrack:done() end

---creates a new scope under this variable tracker
---
---```lua
-----[[
---do
---  ...
---]]
---local sub_tracker = tracker:scope()
---```
---@return var-track.VarTrack
function VarTrack:scope() end

return VarTrackClass

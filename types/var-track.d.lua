---@meta

---holds all data pertaining to the usage of a variable
---@class var-track.var
---the variable's name
---@field name string
---whether the variable is global
---@field global boolean
---whether the variable is a constant
---@field constant boolean
---where the variable was declared
---@field declared any
---where the variable was defined
---@field defined any[]
---where the variable was referenced
---@field referenced any[]

---a diagnostic emission. It typically represents a problem with how a variable
---was used.
---@class var-track.diagnostic
---the type of diagnostic
---@field type string
---data associated with the diagnostic
---@field data any
---the variable affected by the diagnostic
---@field var var-track.var

---a class that implements variable tracking. Instantiating this means creating
---a scope. This is typically used to represent a module's root scope.
---
---```lua
---do -- var_track = VarTrack()
---  -- ...
---```
---@class var-track.VarTrack.Class
---@overload fun(globals?: string[]): var-track.VarTrack
local VarTrackClass = {}

---a variable tracker
---@class var-track.VarTrack
---@field declared { [string]: var-track.var }
---@field diagnostics var-track.diagnostic[]
---@field parent var-track.VarTrack
local VarTrack = {}

---declares a variable `name`
---
---```lua
---local foo -- var_track:declare('foo')
---```
---@param name string
---@param data? any
---@return var-track.var
function VarTrack:declare(name, data) end

---defines a variable `name`
---
---```lua
---foo = 5 -- var_track:define('foo')
---```
---@param name string
---@param data? any
function VarTrack:define(name, data) end

---references a variable `name`
---
---```lua
---foo() -- var_track:reference('foo')
---```
---@param name string
---@param data? any
function VarTrack:reference(name, data) end

---ends this variable tracker's scope
---
---```lua
---  -- ...
---end -- var_track:done()
---```
function VarTrack:done() end

---creates a new scope under this variable tracker
---
---```lua
---  -- ...
---  do -- sub_track = var_track:scope()
---    -- ...
---```
---@return var-track.VarTrack
function VarTrack:scope() end

return VarTrackClass

---@meta

---@alias var-track.data unknown

---@class var-track.var
---@field name string
---@field global boolean
---@field constant boolean
---@field declared var-track.data
---@field defined var-track.data[]
---@field referenced var-track.data[]

---@class var-track.diagnostic
---@field type string
---@field data var-track.data
---@field var var-track.var

---a class that implements variable tracking. Instantiating this means creating
---a scope. This is typically used to represent the root scope.
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
---@param data? var-track.data
---@return var-track.var
function VarTrack:declare(name, data) end

---defines a variable `name`
---
---```lua
---foo = 5 -- var_track:define('foo')
---```
---@param name string
---@param data? var-track.data
function VarTrack:define(name, data) end

---references a variable `name`
---
---```lua
---foo() -- var_track:reference('foo')
---```
---@param name string
---@param data? var-track.data
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

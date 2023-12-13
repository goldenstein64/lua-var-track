local muun = require("var-track.muun")

---@alias var-track.data unknown

---@class var-track.var
---the name of this variable
---@field name string
---whether this variable is a global
---@field global boolean
---whether this variable is a constant
---@field constant boolean
---where this variable is declared
---@field declared var-track.data
---where this variable is defined
---@field defined var-track.data[]
---where this variable is referenced
---@field referenced var-track.data[]
---what this variable is shadowing
---@field shadow var-track.var?

---@class var-track.diagnostic
---@field type string
---@field data var-track.data
---@field var var-track.var

---@class var-track.VarTrack
---@field declared { [string]: var-track.var }
---@field diagnostics var-track.diagnostic[]
local VarTrack = muun("VarTrack")

---@class var-track.VarTrack.Class
---@overload fun(...: string): var-track.VarTrack
local VarTrackClass = VarTrack --[[@as var-track.VarTrack.Class]]

---declares a new scope
---@param ... string
function VarTrack:new(...)
	self.declared = {}
	self.diagnostics = {}
	if select("#", ...) > 0 then
		for _, name in ipairs({ ... }) do
			self.declared[name] = {
				name = name,
				global = true,
				constant = false,
				declared = true,
				defined = {},
				referenced = {},
			}
		end
	end
end

---creates a variable called `name`
---
---```lua
---local x
----- v:declare('x')
---```
---@param name string
---@param data any
---@return var-track.var
function VarTrack:declare(name, data)
	if data == nil then
		data = true
	end

	---@type var-track.var
	local var = {
		name = name,
		global = false,
		constant = false,
		declared = data,
		defined = {},
		referenced = {},
	}

	local old_var = self.declared[name]
	if old_var then
		if not old_var.global then
			---@type var-track.diagnostic
			local diag = { type = "shadowed_local", data = data, var = old_var }
			table.insert(self.diagnostics, diag)
		end
		var.shadow = old_var
	end

	self.declared[name] = var
	return var
end

---gives a variable called `name` a value
---
---```lua
---x = 3
----- v:define('x')
---```
---@param name string
---@param data? any
---@return var-track.var
function VarTrack:define(name, data)
	if data == nil then
		data = true
	end

	local var = self.declared[name]
	if not var then
		---@type var-track.var
		var = {
			name = name,
			global = true,
			constant = false,
			declared = data,
			defined = {},
			referenced = {},
		}
		self.declared[name] = var

		---@type var-track.diagnostic
		local diag = { type = "defined_global", data = data, var = var }
		table.insert(self.diagnostics, diag)
	end

	if var.constant and #var.defined > 0 then
		---@type var-track.diagnostic
		local diag = { type = "redefined_constant", data = data, var = var }
		table.insert(self.diagnostics, diag)
	end

	table.insert(var.defined, data)
	return var
end

---evaluates a variable called `name`
---
---```lua
---x()
----- v:reference('x')
---```
---@param name string
---@param data? any
---@return var-track.var
function VarTrack:reference(name, data)
	if data == nil then
		data = true
	end

	local var = self.declared[name]
	if not var then
		---@type var-track.var
		var = {
			name = name,
			global = true,
			constant = false,
			declared = data,
			defined = {},
			referenced = {},
		}

		-- I'm not sure if this is the best idea...
		self.declared[name] = var

		---@type var-track.diagnostic
		local diag = { type = "unknown_global", data = data, var = var }
		table.insert(self.diagnostics, diag)
	end

	if not var.global and #var.defined <= 0 then
		---@type var-track.diagnostic
		local diag = { type = "uninitialized_local", data = data, var = var }
		table.insert(self.diagnostics, diag)
	end

	table.insert(var.referenced, data)
	return var
end

---@param self var-track.VarTrack
---@param var var-track.var
local function check_unused(self, var)
	if not var.global and #var.referenced <= 0 then
		---@type var-track.diagnostic
		local diag = { type = "unused_local", data = var.declared, var = var }
		table.insert(self.diagnostics, diag)
	end

	if var.shadow then
		check_unused(self, var.shadow)
	end
end

---declares that this tracker's scope has ended. This adds diagnostics
---for unused locals
function VarTrack:done()
	for _, var in pairs(self.declared) do
		check_unused(self, var)
	end
end

---declares a new scope in this scope
---@return var-track.VarTrack
function VarTrack:scope()
	local result = VarTrack()
	setmetatable(result.declared, { __index = self.declared })
	return result
end

return VarTrackClass

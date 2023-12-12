local muun = require("var-track.muun")

---@alias var-track.data any

---@class var-track.var_info
---the name of this variable
---@field name string
---whether this variable is a global
---@field global boolean
---whether this variable is a constant
---@field const boolean
---where this variable is declared
---@field declared var-track.data
---where this variable is defined
---@field defined var-track.data[]
---where this variable is referenced
---@field referenced var-track.data[]
---what this variable is shadowing
---@field shadowing var-track.var_info?

---@class var-track.diagnostic
---@field type string
---@field data var-track.data
---@field var var-track.var_info

---@class var-track.VarTrack
---@field declared { [string]: var-track.var_info }
---@field diagnostics var-track.diagnostic[]
---@overload fun(...: string): var-track.VarTrack
local VarTrack = muun("VarTrack")

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
				defined = {},
				referenced = {},
				const = false,
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
---@return var-track.var_info
function VarTrack:declare(name, data)
	if data == nil then
		data = true
	end

	---@type var-track.var_info
	local var_info = {
		name = name,
		global = false,
		defined = {},
		referenced = {},
		const = false,
		declared = data,
	}

	local old_var_info = self.declared[name]
	if old_var_info then
		if not old_var_info.global then
			---@type var-track.diagnostic
			local diag = { type = "shadowed_local", data = data, var = old_var_info }
			table.insert(self.diagnostics, diag)
		end
		var_info.shadowing = old_var_info
	end

	self.declared[name] = var_info
	return var_info
end

---gives a variable called `name` a value
---
---```lua
---x = 3
----- v:define('x')
---```
---@param name string
---@param data? any
---@return var-track.var_info
function VarTrack:define(name, data)
	if data == nil then
		data = true
	end

	local var_info = self.declared[name]
	if not var_info then
		---@type var-track.var_info
		var_info = {
			name = name,
			global = true,
			defined = {},
			referenced = {},
			const = false,
			declared = data
		}
		self.declared[name] = var_info

		---@type var-track.diagnostic
		local diag = { type = "defined_global", data = data, var = var_info }
		table.insert(self.diagnostics, diag)
	end

	if var_info.const and #var_info.defined > 0 then
		---@type var-track.diagnostic
		local diag = { type = "redefined_constant", data = data, var = var_info }
		table.insert(self.diagnostics, diag)
	end

	table.insert(var_info.defined, data)
	return var_info
end

---evaluates a variable called `name`
---
---```lua
---x()
----- v:reference('x')
---```
---@param name string
---@param data? any
---@return var-track.var_info
function VarTrack:reference(name, data)
	if data == nil then
		data = true
	end

	local var_info = self.declared[name]
	if not var_info then
		---@type var-track.var_info
		var_info = {
			name = name,
			global = true,
			defined = {},
			referenced = {},
			const = false,
			declared = data,
		}

		-- I'm not sure if this is the best idea...
		self.declared[name] = var_info

		---@type var-track.diagnostic
		local diag = { type = "unknown_global", data = data, var = var_info }
		table.insert(self.diagnostics, diag)
	end

	if not var_info.global and #var_info.defined <= 0 then
		---@type var-track.diagnostic
		local diag = { type = "uninitialized_local", data = data, var = var_info }
		table.insert(self.diagnostics, diag)
	end

	table.insert(var_info.referenced, data)
	return var_info
end

---@param self var-track.VarTrack
---@param var_info var-track.var_info
local function check_unused(self, var_info)
	if not var_info.global and #var_info.referenced <= 0 then
		---@type var-track.diagnostic
		local diag = { type = "unused_local", data = var_info.declared, var = var_info }
		table.insert(self.diagnostics, diag)
	end

	if var_info.shadowing then
		check_unused(self, var_info.shadowing)
	end
end

---declares that this tracker's scope has ended. This adds diagnostics
---for unused locals
function VarTrack:done()
	for _, var_info in pairs(self.declared) do
		check_unused(self, var_info)
	end
end

---declares a new scope in this scope
---@return var-track.VarTrack
function VarTrack:block()
	local result = VarTrack()
	setmetatable(result.declared, { __index = self.declared })
	return result
end

return VarTrack

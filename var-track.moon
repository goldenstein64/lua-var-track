import insert from table

---holds all data pertaining to the usage of a variable
---@shape var-track.var
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
---the variable this is shadowing if any
---@field shadow var-track.var?

---a local was declared but never referenced
---@shape var-track.diagnostic.unused_local
---@field type "unused_local"
---@field var var-track.var

---a local was re-declared over another local
---@shape var-track.diagnostic.shadowed_local
---@field type "shadowed_local"
---@field var var-track.var

---a *new* global was defined
---@shape var-track.diagnostic.defined_global
---@field type "defined_global"
---@field var var-track.var

---a constant was defined more than once
---@shape var-track.diagnostic.redefined_constant
---@field type "redefined_constant"
---@field data any
---@field var var-track.var

---a global was referenced but never defined
---@shape var-track.diagnostic.unknown_global
---@field type "unknown_global"
---@field var var-track.var

---a local was referenced but never defined
---@shape var-track.diagnostic.uninitialized_local
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

---@param name string
---@param declared any
---@return var-track.var
VarInfo = (name, declared=true) ->
	{
		:name
		global: false
		constant: false
		:declared
		defined: {}
		referenced: {}
	}

---@param self var-track.VarTrack
---@param var var-track.var
check_unused = (var) =>
	if not var.global and #var.referenced <= 0
		insert @diagnostics, { type: 'unused_local', :var }

	check_unused @, var.shadow if var.shadow

---@param self var-track.VarTrack
---@param var var-track.var
push_global = (var) =>
	@parent.declared[var.name] = var if var.global

	push_global @, var.shadow if var.shadow

---a class that implements variable tracking. Instantiating this means a
---program has begun.
---
---```lua
----- beginning of program
---tracker = VarTrack globals
---```
---
---Examples:
---
---```moon
----- local foo
----- foo = 5
-----
----- foo *= 10
-----
----- print foo
---
---
---globals = { name, { data... } for name in pairs _G }
---tracker = VarTrack globals
---
-----local foo
---tracker\declare "foo", { data... }
---
----- foo = 5
---tracker\define "foo", { data... }
---
----- foo *= 10
---tracker\reference "foo", { data... }
---tracker\define "foo", { data... }
---
----- print foo
---tracker\reference "print", { data... }
---tracker\reference "foo", { data... }
---
---tracker\done!
---```
---@name var-track.VarTrack
class VarTrack

	---initializes a new variable tracker
	---@param globals { [string]: any }
	new: (globals) =>
		@diagnostics = {}
		@declared = {}
		if globals
			for name, data in pairs globals
				var = VarInfo name, data
				var.global = true
				@declared[name] = var

	---declares a variable `name`
	---
	---```moon
	----- local foo
	---tracker\declare 'foo'
	---```
	---
	---The `data` argument is used to store extra information about the variable's
	---declaration.
	---@param name string
	---@param data any
	---@return var-track.var
	declare: (name, data=true) =>
		var = VarInfo name, data

		if old_var = @declared[name]
			var.shadow = old_var
			if not old_var.global
				insert @diagnostics, { type: 'shadowed_local', :var }

		@declared[name] = var
		var

	---defines a variable `name`
	---
	---```moon
	----- foo = 5 -- given foo is already declared
	---tracker\define 'foo'
	---```
	---
	---The `data` argument is used to store extra information about the variable's
	---definition.
	---@param name string
	---@param data any
	define: (name, data=true) =>
		var = @declared[name]
		if not var
			var = VarInfo name, data
			var.global = true
			@declared[name] = var

			insert @diagnostics, { type: 'defined_global', :var }

		if var.constant and #var.defined > 0
			insert @diagnostics, { type: 'redefined_constant', :data, :var }

		insert var.defined, data
		return

	---references a variable `name`
	---
	---```moon
	----- print foo
	---tracker\reference 'print'
	---tracker\reference 'foo'
	---```
	---
	---The `data` argument is used to store extra information about the variable's
	---reference.
	---@param name string
	---@param data any
	reference: (name, data=true) =>
		var = @declared[name]
		if not var
			var = VarInfo name, data
			var.global = true

			-- I'm not sure if this is the best idea...
			@declared[name] = var

			insert @diagnostics, { type: 'unknown_global', :var }

		if not var.global and #var.defined <= 0
			insert @diagnostics, { type: 'uninitialized_local', :data, :var }

		insert var.referenced, data
		return

	---ends this variable tracker's scope
	---
	---```moon
	-----   ...
	----- end
	---local diagnostics = tracker:done()
	---```
	---@return var-track.diagnostic[] diagnostics
	done: =>
		for _, var in pairs @declared
			check_unused @, var

		if @parent
			for _, var in pairs @declared
				push_global @, var

		@diagnostics

	---creates a new scope under this variable tracker
	---
	---```moon
	----- do
	-----   ...
	---local sub_tracker = tracker:scope()
	---```
	---@return var-track.VarTrack
	scope: =>
		result = VarTrack!
		result.parent = @
		setmetatable result.declared, { __index: @declared }
		result




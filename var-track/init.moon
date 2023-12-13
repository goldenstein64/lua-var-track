import insert from table

VarInfo = (name, declared=true) ->
	{
		:name
		global: false
		constant: false
		:declared
		defined: {}
		referenced: {}
	}

check_unused = (var) =>
	if not var.global and #var.referenced <= 0
		insert @diagnostics, { type: 'unused_local', data: var.declared, :var }

	check_unused @, var.shadow if var.shadow

class VarTrack
	new: (globals) =>
		@diagnostics = {}
		@declared = {}
		if globals
			for name in *globals
				var = VarInfo name
				var.global = true
				@declared[name] = var

	declare: (name, data=true) =>
		var = VarInfo name, data

		if old_var = @declared[name]
			if not old_var.global
				insert @diagnostics, { type: 'shadowed_local', :data, var: old_var }
			var.shadow = old_var

		@declared[name] = var
		var

	define: (name, data=true) =>
		var = @declared[name]
		if not var
			var = VarInfo name, data
			var.global = true
			@declared[name] = var

			insert @diagnostics, { type: 'defined_global', :data, :var }

		if var.constant and #var.defined > 0
			insert @diagnostics, { type: 'redefined_constant', :data, :var }

		insert var.defined, data
		var

	reference: (name, data=true) =>
		var = @declared[name]
		if not var
			var = VarInfo name, data
			var.global = true

			-- I'm not sure if this is the best idea...
			@declared[name] = var

			insert @diagnostics, { type: 'unknown_global', :data, :var }

		if not var.global and #var.defined <= 0
			insert @diagnostics, { type: 'uninitialized_local', :data, :var }

		insert var.referenced, data
		var

	done: =>
		check_unused @, var for _, var in pairs @declared

	scope: =>
		result = VarTrack!
		setmetatable result.declared, { __index: @declared }
		result




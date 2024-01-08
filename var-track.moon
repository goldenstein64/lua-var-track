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
		insert @diagnostics, { type: 'unused_local', :var }

	check_unused @, var.shadow if var.shadow

push_global = (var) =>
	@parent.declared[var.name] = var if var.global

	push_global @, var.shadow if var.shadow

class VarTrack
	new: (globals) =>
		@diagnostics = {}
		@declared = {}
		if globals
			for name, data in pairs globals
				var = VarInfo name, data
				var.global = true
				@declared[name] = var

	declare: (name, data=true) =>
		var = VarInfo name, data

		if old_var = @declared[name]
			var.shadow = old_var
			if not old_var.global
				insert @diagnostics, { type: 'shadowed_local', :var }

		@declared[name] = var
		var

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

	done: =>
		for _, var in pairs @declared
			check_unused @, var

		if @parent
			for _, var in pairs @declared
				push_global @, var

		@diagnostics

	scope: =>
		result = VarTrack!
		result.parent = @
		setmetatable result.declared, { __index: @declared }
		result




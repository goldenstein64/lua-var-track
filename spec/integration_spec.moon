import types from require 'tableshape'

VarTrack = require 'var-track'

describe 'VarTrack', ->
	it 'diagnoses unused undefined locals', ->
		-- do
		--   local foo
		-- end

		v = VarTrack!
		var = v\declare 'foo', 'decl_data'
		diagnostics = v\done!

		assert.same {
			{
				type: 'unused_local'
				var: {
					name: 'foo'
					global: false
					constant: false
					declared: 'decl_data'
					defined: {}
					referenced: {}
				}
			}
		}, diagnostics

	it 'diagnoses unused defined locals', ->
		-- do
		--   local foo
		--   foo = 5
		-- end

		v = VarTrack!
		var = v\declare 'foo', 'decl_data'
		v\define 'foo', 'def_data'
		diagnostics = v\done!

		assert.same {
			{
				type: 'unused_local'
				var: {
					name: 'foo'
					global: false
					constant: false
					declared: 'decl_data'
					defined: { 'def_data' }
					referenced: {}
				}
			}
		}, diagnostics


	it 'diagnoses uninitialized locals', ->
		-- do
		--   local foo
		--   foo()
		-- end

		v = VarTrack!
		var = v\declare 'foo', 'decl_data'
		v\reference 'foo', 'ref_data'
		diagnostics = v\done!

		assert.same {
			{
				type: 'uninitialized_local'
				data: 'ref_data'
				var: {
					name: 'foo'
					global: false
					constant: false
					declared: 'decl_data'
					defined: {}
					referenced: { 'ref_data' }
				}
			}
		}, diagnostics

	it 'diagnoses shadowed locals', ->
		-- do
		--   local foo
		--   local foo
		-- end

		v = VarTrack!
		var1 = v\declare 'foo', 'decl1_data'
		var2 = v\declare 'foo', 'decl2_data'
		diagnostics = v\done!

		expected_var1 = {
			name: 'foo'
			global: false
			constant: false
			declared: 'decl1_data'
			defined: {}
			referenced: {}
		}

		expected_var2 = {
			name: 'foo'
			global: false
			constant: false
			declared: 'decl2_data'
			defined: {}
			referenced: {}
			shadow: expected_var1
		}

		assert.same {
			{ -- caught in second declaration
				type: 'shadowed_local'
				var: expected_var2
			}, { -- caught when scope ends
				type: 'unused_local'
				var: expected_var2
			}, { -- caught when scope ends
				type: 'unused_local'
				var: expected_var1
			}
		}, diagnostics

	it 'diagnoses defined globals', ->
		-- do
		--   foo = 5
		-- end

		v = VarTrack!
		v\define 'foo', 'def_data'
		diagnostics = v\done!

		assert.same {
			{
				type: 'defined_global'
				var: {
					name: 'foo'
					global: true
					constant: false
					declared: 'def_data'
					defined: { 'def_data' }
					referenced: {}
				}
			}
		}, diagnostics

	it 'diagnoses unknown globals', ->
		-- do
		--   foo()
		-- end

		v = VarTrack!
		v\reference 'foo', 'ref_data'
		diagnostics = v\done!

		assert.same {
			{
				type: 'unknown_global'
				var: {
					name: 'foo'
					global: true
					constant: false
					declared: 'ref_data'
					defined: {}
					referenced: { 'ref_data' }
				}
			}
		}, diagnostics

	it 'diagnoses redefined constant', ->
		-- do
		--   local foo ---@const
		--   foo = 5
		--   foo = 5
		-- end

		v = VarTrack!
		foo = v\declare 'foo', 'decl_data'
		foo.constant = true
		v\define 'foo', 'def1_data'
		v\define 'foo', 'def2_data'
		v\reference 'foo', 'ref_data'
		diagnostics = v\done!

		assert.same {
			{
				type: 'redefined_constant'
				data: 'def2_data'
				var: {
					name: 'foo'
					global: false
					constant: true
					declared: 'decl_data'
					defined: { 'def1_data', 'def2_data' }
					referenced: { 'ref_data' }
				}
			}
		}, diagnostics

	it "doesn't diagnose shadowed globals", ->
		-- _G = { foo = 5 }
		-- do
		--   local foo
		--   foo = 5
		--   foo()
		-- end

		v = VarTrack { ['foo']: 'decl_data1' }
		global_foo = v.declared['foo']
		local_foo = v\declare 'foo', 'decl_data2'
		v\define 'foo', 'def2_data'
		v\reference 'foo', 'ref_data'
		diagnostics = v\done!

		assert.equal local_foo.shadow, global_foo
		assert.same {}, diagnostics

	it 'diagnoses unused shadowed locals', ->
		-- do
		--   local foo
		--   foo = 5
		--   local foo
		--   foo = 5
		--   foo()
		-- end

		v = VarTrack!
		var1 = v\declare 'foo', 'decl1_data'
		v\define 'foo', 'def1_data'
		var2 = v\declare 'foo', 'decl2_data'
		v\define 'foo', 'def2_data'
		v\reference 'foo', 'ref2_data'
		diagnostics = v\done!

		var1_data = {
			name: 'foo'
			global: false
			constant: false
			declared: 'decl1_data'
			defined: { 'def1_data' }
			referenced: {}
		}

		var2_data = {
			name: 'foo'
			global: false
			constant: false
			declared: 'decl2_data'
			defined: { 'def2_data' }
			referenced: { 'ref2_data' }
			shadow: var1_data
		}

		assert.same {
			{
				type: 'shadowed_local'
				var: var2_data
			}, {
				type: 'unused_local'
				var: var1_data
			}
		}, diagnostics

	it 'diagnoses two unused locals', ->
		-- do
		--   local foo
		--   local bar
		--   foo = 5
		--   bar = 5
		-- end

		v = VarTrack!
		v\declare 'foo', 'decl1'
		v\declare 'bar', 'decl2'
		v\define 'foo', 'def1'
		v\define 'bar', 'def2'
		diagnostics = v\done!

		diag1 = types.shape {
			type: 'unused_local'
			var: types.shape {
				name: 'foo'
				global: false
				constant: false
				declared: 'decl1'
				defined: types.shape { 'def1' }
				referenced: types.shape {}
			}
		}
		diag2 = types.shape {
			type: 'unused_local'
			var: types.shape {
				name: 'bar'
				global: false
				constant: false
				declared: 'decl2'
				defined: types.shape { 'def2' }
				referenced: types.shape {}
			}
		}

		comb1 = types.shape { diag1, diag2 }
		comb2 = types.shape { diag2, diag1 }

		assert.shape diagnostics, types.one_of { comb1, comb2 }

	it 'lets inner globals reach outer scopes', ->
		-- do
		--   do
		--     foo = 5
		--   end
		-- end

		v = VarTrack!
		w = v\scope!
		global = w\define 'foo', 'def'
		w\done!
		v\done!

		assert.truthy v.declared['foo']

	it 'can define from an inner scope', ->
		-- do
		--   local foo
		--   do
		--     foo = 5
		--   end
		--   foo()
		-- end

		v = VarTrack!
		v\declare 'foo'
		w = v\scope!
		w\define 'foo'
		w_diagnostics = w\done!
		v\reference 'foo'
		v_diagnostics = v\done!

		assert.same {}, w_diagnostics
		assert.same {}, v_diagnostics

	it 'can reference from an inner scope', ->
		-- do
		--   local foo
		--   foo = 5
		--   do
		--     foo()
		--   end
		-- end

		v = VarTrack!
		v\declare 'foo'
		v\define 'foo'
		w = v\scope!
		w\reference 'foo'
		w_diagnostics = w\done!
		v_diagnostics = v\done!

		assert.same {}, w_diagnostics
		assert.same {}, v_diagnostics

	it 'cannot declare from an inner scope', ->
		-- do
		--   do
		--     local foo
		--   end
		--   foo = 5
		-- end

		v = VarTrack!
		w = v\scope!
		w\declare 'foo', 'decl'
		w_diagnostics = w\done!
		v\define 'foo', 'def'
		v_diagnostics = v\done!

		assert.same {
			{
				type: 'unused_local'
				var: {
					name: 'foo'
					global: false
					constant: false
					declared: 'decl'
					defined: {}
					referenced: {}
				}
			}
		}, w_diagnostics

		assert.same {
			{
				type: 'defined_global'
				var: {
					name: 'foo'
					global: true
					constant: false
					declared: 'def'
					defined: { 'def' }
					referenced: {}
				}
			}
		}, v_diagnostics

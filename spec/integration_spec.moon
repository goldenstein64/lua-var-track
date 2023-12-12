VarTrack = require 'var-track'

describe 'VarTrack', ->
	it 'diagnoses unused undefined locals', ->
		-- do
		--   local foo
		-- end

		v = VarTrack!
		var = v\declare 'foo', 'decl_data'
		v\done!

		assert.same {
			{
				type: 'unused_local'
				data: 'decl_data'
				var: {
					name: 'foo'
					global: false
					const: false
					declared: 'decl_data'
					defined: {}
					referenced: {}
				}
			}
		}, v.diagnostics

	it 'diagnoses unused defined locals', ->
		-- do
		--   local foo
		--   foo = 5
		-- end

		v = VarTrack!
		var = v\declare 'foo', 'decl_data'
		v\define 'foo', 'def_data'
		v\done!

		assert.same {
			{
				type: 'unused_local'
				data: 'decl_data'
				var: {
					name: 'foo'
					global: false
					const: false
					declared: 'decl_data'
					defined: { 'def_data' }
					referenced: {}
				}
			}
		}, v.diagnostics


	it 'diagnoses uninitialized locals', ->
		-- do
		--   local foo
		--   foo()
		-- end

		v = VarTrack!
		var = v\declare 'foo', 'decl_data'
		v\reference 'foo', 'ref_data'
		v\done!

		assert.same {
			{
				type: 'uninitialized_local'
				data: 'ref_data'
				var: {
					name: 'foo'
					global: false
					const: false
					declared: 'decl_data'
					defined: {}
					referenced: { 'ref_data' }
				}
			}
		}, v.diagnostics

	it 'diagnoses shadowed locals', ->
		-- do
		--   local foo
		--   local foo
		-- end

		v = VarTrack!
		var1 = v\declare 'foo', 'decl1_data'
		var2 = v\declare 'foo', 'decl2_data'
		v\done!

		assert.same {
			{
				type: 'shadowed_local'
				data: 'decl2_data'
				var: {
					name: 'foo'
					global: false
					const: false
					declared: 'decl1_data'
					defined: {}
					referenced: {}
				}
			}, {
				type: 'unused_local'
				data: 'decl2_data'
				var: {
					name: 'foo'
					global: false
					const: false
					declared: 'decl2_data'
					defined: {}
					referenced: {}
				}
			}
		}, v.diagnostics

	it 'diagnoses defined globals', ->
		-- do
		--   foo = 5
		-- end

		v = VarTrack!
		v\define 'foo', 'def_data'
		v\done!

		assert.same {
			{
				type: 'defined_global'
				data: 'def_data'
				var: {
					name: 'foo'
					global: true
					const: false
					declared: 'def_data'
					defined: { 'def_data' }
					referenced: {}
				}
			}
		}, v.diagnostics



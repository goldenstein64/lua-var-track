# lua-var-track

A tool used to track the state of Lua variables as they are used throughout a program. This can be used to store types and other information, and it also records diagnostics for accidental globals and unused variables.

The typical use case for this library is in the implementation of analysis in a language server that compiles to Lua. Information about variables can be stored in the tracker's properties.

## Installation

`var-track.lua` is the only file dependency, so it can be copy-pasted into a project easily, but it can also be installed via LuaRocks as shown below.

```sh
# Note that this rock hasn't been uploaded yet!
$ luarocks --dev install var-track
```

Lua language server types are also included with the module, under `lua_modules/lib/rocks-5.1/var-track/{VERSION}/types`.

## Usage

This tool should be used to track variables by ordering declarations, definitions, and references the way the program does when running. e.g.

```lua
-- local VarTrack = require("var-track")

-- beginning of the program
-- local globals = {}
-- for name in pairs(_G) do
--   table.insert(globals, name)
-- end
-- local tracker = VarTrack(globals)

-- tracker:declare("x", { data... })
local x

-- tracker:define("x", { data... })
x = 1

-- tracker:reference("print", { data... })
-- tracker:reference("x", { data... })
print(x)

-- end of the program
-- tracker:done()
-- analyze tracker.diagnostics and tracker.declared
```

The `var-track` module is a class, called `VarTrack` in this document.

- When a program starts, the class gets instantiated as `VarTrack(globals)`. In this document, an instance of this is called a `tracker`.
- When a local variable is declared, `tracker:declare(name, data)` is called. It returns a table describing what information was stored about the variable. It's the same table stored at `tracker.declared[name]`.
- When a variable is defined, `tracker:define(name, data)` is called.
- When a variable is referenced, `tracker:reference(name, data)` is called.
- When a block is declared (like `do ... end`), `tracker:scope()` is called. This returns a new tracker with the same API. This new tracker should be used while the block is active.
- When the program or block reaches the end of evaluation, i.e. when an `end` is reached, `tracker:done()` is called.

The `data` argument is used to store information about the variable at that point of the program. For example, `tracker:define` might store what the variable's type is after this definition. The default value for the `data` argument is `true`.

Whenever a variable is declared through any of the variable usage methods, it generates an entry in `tracker.declared`, where the key is the variable name and the value is a table of information about the variable with the following keys:

| Key          | Type        | Description                                    |
|--------------|-------------|------------------------------------------------|
| `name`       | `string`    | the variable's name                            |
| `global`     | `boolean`   | is this a global?                              |
| `constant`   | `boolean`   | is this a constant? (can only be defined once) |
| `declared`   | `data`      | declaration information                        |
| `defined`    | `data[]`    | definition information                         |
| `referenced` | `data[]`    | reference information                          |
| `shadow`     | `variable?` | a variable if this shadowed one                |

Whenever the tracker detects improper usage of a variable, it appends a table to its list in `tracker.diagnostics`. Each table contains these keys:

| Key    | Type        | Description                         |
|--------|-------------|-------------------------------------|
| `type` | `string`    | type of diagnostic                  |
| `data` | `data`      | data associated with the diagnostic |
| `var`  | `variable`  | variable affected by the diagnostic |

The `type` field can be one of the following strings:
- `"unused_local"` - a local was declared but never referenced
  - `var` holds the variable that wasn't used
- `"shadowed_local"` - a local was re-declared over another local
  - `var` holds the new variable. The old variable is in its `shadow` field.
- `"defined_global"` - a *new* global was defined
  - `var` holds the global that was defined
- `"redefined_constant"` - a constant was defined more than once
  - `data` holds the new definition data
  - `var` holds the constant that was redefined
- `"unknown_global"` - a global was referenced but never defined. This creates a new global.
  - `var` holds the global that was referenced and generated
- `"uninitialized_local"` - a local was referenced but never defined
  - `data` holds the new reference data
  - `var` holds the variable that was referenced

If the `data` field is present, it holds the value passed in as a second argument to the variable usage method that generated this diagnostic. If it's not present, it's can be found in the variable's info table.

The `var` field is a reference to a variable table in `tracker.declared`.

Diagnostics in trackers created with `tracker:block()` aren't passed to their parent tracker.

## API

The `var-track` module exports a class, which is called `VarTrack` in this document. It's defined as a MoonScript class, so it has all the `MoonScript` semantics like `__name`, `__base`, etc.

### `VarTrack(globals: string[]) -> VarTrack`

a class that implements variable tracking. Instantiating this means a program has begun.

```lua
-- beginning of program
-- local var_track = VarTrack(globals)
```

Examples:

```lua
-- local globals = {}
-- for k in pairs(_G) do
--   table.insert(globals, k)
-- end
-- local var_track = VarTrack(globals)

local foo = 5
-- var_track:declare("foo")
-- var_track:define("foo")

foo = foo * 10
-- var_track:reference("foo")
-- var_track:define("foo")

print(foo)
-- var_track:reference("print")
-- var_track:reference("foo")
```

### `tracker:declare(name: string, data?: any) -> variable`

declares a variable `name`

```lua
local foo -- var_track:declare('foo')
```

The `data` argument is used to store extra information about the variable's declaration.

### `tracker:define(name: string, data?: any)`

defines a variable `name`

```lua
foo = 5 -- var_track:define('foo')
```

The `data` argument is used to store extra information about the variable's definition.

### `tracker:reference(name: string, data?: any)`

references a variable `name`

```lua
-- var_track:reference('print')
-- var_track:reference('foo')
print(foo)
```

The `data` argument is used to store extra information about the variable's reference.

### `tracker:done() -> diagnostic[]`

ends this variable tracker's scope

```lua
  -- ...
end -- var_track:done()
```

### `tracker:scope() -> VarTrack`

creates a new scope under this variable tracker

```lua
-- ...
do -- sub_track = var_track:scope()
  -- ...
```

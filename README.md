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
--[[
local x

x = 1

print(x)
]]

local VarTrack = require("var-track")

-- beginning of the program
local globals = {}
for name in pairs(_G) do
  globals[name] = { data, ... }
end
local tracker = VarTrack(globals)

tracker:declare("x", { data, ... }) -- local x

tracker:define("x", { data, ... }) -- x = 1

tracker:reference("print", { data, ... }) -- print(x)
tracker:reference("x", { data, ... }) -- print(x)

-- end of the program
local diagnostics = tracker:done()
-- analyze diagnostics and tracker.declared
```

The `var-track` module is a class called `VarTrack` in this document.

- When a program starts, the class gets instantiated as `VarTrack(globals)`. In this document, an instance of this is called a `tracker`.
- When a local variable is declared, `tracker:declare(name, data)` is called. It returns a table describing what information was stored about the variable. It's the same table stored at `tracker.declared[name]`.
- When a variable is defined, `tracker:define(name, data)` is called.
- When a variable is referenced, `tracker:reference(name, data)` is called.
- When a block is declared (like `do ... end`), `tracker:scope()` is called. This returns a new tracker with the same API. This new tracker should be used while the block is active.
- When the program or block reaches the end of evaluation, i.e. when an `end` is reached, `tracker:done()` is called.

The `data` argument is used to store information about the variable at that point of the program. For example, `tracker:define` might store what the variable's type is after this definition. The default value for the `data` argument is `true`.

Whenever a variable is declared through any of the variable usage methods, it generates an entry in `tracker.declared`, where the key is the variable name and the value is a table of information about the variable with the following keys:

| Key          | Type        | Description                                            |
|--------------|-------------|--------------------------------------------------------|
| `name`       | `string`    | the variable's name                                    |
| `owner`      | `VarTrack?` | the tracker this variable belongs to (`nil` if global) |
| `constant`   | `boolean`   | is this a constant? (can only be defined once)         |
| `declared`   | `data`      | declaration information                                |
| `defined`    | `data[]`    | definition information                                 |
| `referenced` | `data[]`    | reference information                                  |
| `shadow`     | `variable?` | a variable if this shadowed one                        |

Whenever the tracker detects improper usage of a variable, it appends a table to its list in `tracker.diagnostics`. Each table will have a `type` key, but any additional keys are determined by the `type` key.

The `type` key can be one of the following strings. The available properties are listed below it.

- `"unused_local"` - a local was declared but never referenced
  - `var: variable` holds the variable that wasn't used
- `"shadowed_local"` - a local was re-declared over another local
  - `var: variable` holds the new variable. The old variable is in the new variable's `shadow` field.
- `"defined_global"` - a *new* global was defined
  - `var: variable` holds the global that was defined
- `"redefined_constant"` - a constant was defined more than once
  - `data: data` holds the new definition data
  - `var: variable` holds the constant that was redefined
- `"unknown_global"` - a global was referenced but never defined. This creates a new global.
  - `var: variable` holds the global that was referenced and generated
- `"uninitialized_local"` - a local was referenced but never defined
  - `data: data` holds the new reference data
  - `var: variable` holds the variable that was referenced

Diagnostics in trackers created with `tracker:block()` aren't passed to their parent tracker.

## Gotchas

### `unknown_global` diagnostics for function definitions

Because diagnostics are generated as the usage methods are called, function definitions won't see globals defined in the future, meaning an `unknown_global` diagnostic will be generated even though it was defined later in the script.

```lua
--[[
local function foo()
  print(GLOBAL)
end

GLOBAL = 1

print(GLOBAL)
]]

tracker:declare("foo")
tracker:define("foo")

local foo_tracker = tracker:scope() do
  foo_tracker:reference("print")
  foo_tracker:reference("GLOBAL") -- creates `unknown_global` diagnostic
  foo_tracker:done()
end

tracker:define("GLOBAL") -- creates `defined_global` diagnostic

tracker:reference("print")
tracker:reference("GLOBAL")
tracker:done()
```

And it's not a good idea to evaluate function definitions at the end of the script because function definitions don't capture future local upvalues.

```lua
--[[
local function foo()
  print(later_var)
end

local later_var = 1

print(later_var)
]]

tracker:declare("foo")
tracker:define("foo")

tracker:declare("later_var")
tracker:define("later_var")

tracker:reference("print")
tracker:reference("later_var")

local foo_tracker = tracker:scope() do
  foo_tracker:reference("print")
  foo_tracker:reference("later_var") -- no diagnostic generated!
  foo_tracker:done()
end
tracker:done()
```

The simplest and most performant solution to this is to make a preemptive pass that detects all globals and puts them in the tracker. Function definitions are evaluated when encountered.

```lua
--[[
local function foo()
  print(GLOBAL)
end

GLOBAL = 1

print(GLOBAL)
]]

local future_globals = {}
-- populate future_globals with key-values on first pass

local globals = { ... } -- populated with default globals
for k, v in pairs(future_globals) do
  globals[k] = v
end

local tracker = VarTrack(globals) -- ...
-- continue second pass with `tracker`
```

This, however, assumes that functions aren't called before a global is defined, e.g.

```lua
local function foo()
  print(GLOBAL)
end

foo() -- false positive
GLOBAL = 1
foo()
```

This caveat is probably simpler to live with than other alternatives since doing this correctly requires analyzing how a program runs across multiple files.

## API

The `var-track` module exports a class, which is called `VarTrack` in this document. It's defined as a MoonScript class, so it has all the `MoonScript` semantics like `__name`, `__base`, etc.

### `VarTrack(globals: { [string]: data }) -> VarTrack`

a class that implements variable tracking. Instantiating this typically means a program has begun.

```lua
-- beginning of program
local var_track = VarTrack(globals)
```

Examples:

```lua
--[[
local foo = 5

foo = foo * 10

print(foo)
]]

local globals = {}
for name in pairs(_G) do
  globals[name] = { data... }
end
local tracker = VarTrack(globals)

-- local foo = 5
tracker:declare("foo", { data... })
tracker:define("foo", { data... })

-- foo = foo * 10
tracker:reference("foo", { data... })
tracker:define("foo", { data... })

-- print(foo)
tracker:reference("print", { data... })
tracker:reference("foo", { data... })
```

### `tracker:declare(name: string, data?: data) -> variable`

declares a variable `name`

```lua
-- local foo
tracker:declare("foo")
```

The `data` argument is used to store extra information about the variable's declaration.

### `tracker:define(name: string, data?: data)`

defines a variable `name`

```lua
-- foo = 5
tracker:define('foo')
```

The `data` argument is used to store extra information about the variable's definition.

### `tracker:reference(name: string, data?: data)`

references a variable `name`

```lua
-- print(foo)
tracker:reference('print')
tracker:reference('foo')
```

The `data` argument is used to store extra information about the variable's reference.

### `tracker:scope() -> VarTrack`

creates a new scope under this variable tracker

```lua
--[[
do
  ...
]]
local sub_tracker = tracker:scope()
```

### `tracker:done() -> diagnostic[]`

ends this variable tracker's scope

```lua
--[[
  ...
end
]]
tracker:done()
```

The tracker's diagnostics are returned. After calling this, the tracker should
be treated like a read-only object, and none of the above methods should be used.

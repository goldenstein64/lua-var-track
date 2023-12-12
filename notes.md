```lua
v = vars(
  -- define globals here
  "_G",
  "math", "string", "table",
  "io", "os", "debug",
  -- ...
)

v:declare(name)
v:define(name)
v:reference(name)
v:done()

-- same API as vars(), except it takes no args
b = v:block()

errors = v:diagnose()
```

Examples:

```lua
-- action: global defined
-- info: defined global
-- this variable can be used elsewhere, best not to mark it as unused
v:define(name1)

-- action: global referenced
-- warning: unknown global
v:reference(name2)

-- action: local created
-- warning: unused local
v:declare(name3)
v:define(name3) -- *

-- action: local created
-- warning: uninitialized local
v:declare(name4)
v:reference(name4) -- +

-- typical use case
-- creates a local
v:declare(name5)
v:define(name5) -- +
v:reference(name5) -- +
```

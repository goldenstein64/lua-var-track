local insert
insert = table.insert
local VarInfo
VarInfo = function(owner, name, declared)
  if declared == nil then
    declared = true
  end
  return {
    owner = owner,
    name = name,
    constant = false,
    declared = declared,
    defined = { },
    referenced = { }
  }
end
local check_unused
check_unused = function(self, var)
  if var.owner == self and #var.referenced <= 0 then
    insert(self.diagnostics, {
      type = 'unused_local',
      var = var
    })
  end
  if var.shadow then
    return check_unused(self, var.shadow)
  end
end
local push_global
push_global = function(self, var)
  if not var.owner then
    self.parent.declared[var.name] = var
  end
  if var.shadow then
    return push_global(self, var.shadow)
  end
end
local VarTrack
do
  local _class_0
  local _base_0 = {
    declare = function(self, name, data)
      if data == nil then
        data = true
      end
      local var = VarInfo(self, name, data)
      do
        local old_var = self.declared[name]
        if old_var then
          var.shadow = old_var
          if old_var.owner then
            insert(self.diagnostics, {
              type = 'shadowed_local',
              var = var
            })
          end
        end
      end
      self.declared[name] = var
      return var
    end,
    define = function(self, name, data)
      if data == nil then
        data = true
      end
      local var = self.declared[name]
      if not var then
        var = VarInfo(nil, name, data)
        self.declared[name] = var
        insert(self.diagnostics, {
          type = 'defined_global',
          var = var
        })
      end
      if var.constant and #var.defined > 0 then
        insert(self.diagnostics, {
          type = 'redefined_constant',
          data = data,
          var = var
        })
      end
      insert(var.defined, data)
    end,
    reference = function(self, name, data)
      if data == nil then
        data = true
      end
      local var = self.declared[name]
      if not var then
        var = VarInfo(nil, name, data)
        self.declared[name] = var
        insert(self.diagnostics, {
          type = 'unknown_global',
          var = var
        })
      end
      if var.owner and #var.defined <= 0 then
        insert(self.diagnostics, {
          type = 'uninitialized_local',
          data = data,
          var = var
        })
      end
      insert(var.referenced, data)
    end,
    done = function(self)
      for _, var in pairs(self.declared) do
        check_unused(self, var)
      end
      if self.parent then
        for _, var in pairs(self.declared) do
          push_global(self, var)
        end
      end
      return self.diagnostics
    end,
    scope = function(self)
      do
        local _with_0 = VarTrack()
        _with_0.parent = self
        for k, v in pairs(self.declared) do
          _with_0.declared[k] = v
        end
        return _with_0
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, globals)
      self.diagnostics = { }
      self.declared = { }
      if globals then
        for name, data in pairs(globals) do
          local var = VarInfo(nil, name, data)
          self.declared[name] = var
        end
      end
    end,
    __base = _base_0,
    __name = "VarTrack"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  VarTrack = _class_0
  return _class_0
end

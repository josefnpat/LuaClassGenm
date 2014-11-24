function ask(q)
  io.write(q..": ")
  return io.read()
end

function explode(div,str) -- credit: http://richard.warburton.it
  if (div=='') then return false end
  local pos,arr = 0,{}
  -- for each divider found
  for st,sp in function() return string.find(str,div,pos,true) end do
    table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
    pos = sp + 1 -- Jump past current divider
  end
  table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
  return arr
end

function firstToUpper(str)
  return (str:gsub("^%l", string.upper))
end

s=""
function p(str)
  s = s..str
end

io.write("Lua Class Generator\n")
class_name_raw = ask("Class Name")
class_name = class_name_raw == "" and "anon" or class_name_raw
fast = ask("Fast? (y/N)") == "y"
if fast then
  dead_pool_max = ask("Dead pool max (int)")
end
function_names_raw = ask("functions (csv)")
function_names = function_names_raw == "" and {} or explode(",",function_names_raw)
collection_names_raw = ask("collections (csv)")
collection_names = variable_names_raw == "" and {} or explode(",",collection_names_raw)
variable_names_raw = ask("variables (csv)")
variable_names = variable_names_raw == "" and {} or explode(",",variable_names_raw)

-- CLASS OBJECT
p("local "..class_name.. " = {}\n\n")

-- DEFINED FUNCTIONS
for i,v in pairs(function_names) do
  p("-- TODO\n")
  p("function "..class_name..":"..v.."()\n")
  p("end\n\n")
end

p("-- LuaClassGen pregenerated functions\n\n")

-- NEW FUNCTION
p("function "..class_name..".new()\n")
if fast then
  p("  local self\n")
  p("  if #"..class_name..".__dead_pool > 0 then\n")
  p("    self = table.remove("..class_name..".__dead_pool)\n")
  p("  else\n")
  p("    self = {}\n")
  for i,v in pairs(function_names) do
    p("    self."..v.."="..class_name.."."..v.."\n")
  end
  for i,v in pairs(collection_names) do
    p("    self.add"..firstToUpper(v).."="..class_name..".add"..firstToUpper(v).."\n")
    p("    self.remove"..firstToUpper(v).."="..class_name..".remove"..firstToUpper(v).."\n")
    p("    self.get"..firstToUpper(v).."s="..class_name..".get"..firstToUpper(v).."s\n")
  end
  for i,v in pairs(variable_names) do
    p("    self.get"..firstToUpper(v).."="..class_name..".get"..firstToUpper(v).."\n")
    p("    self.set"..firstToUpper(v).."="..class_name..".set"..firstToUpper(v).."\n")
  end
  p("    table.insert("..class_name..".__live_pool,self)\n")
  p("  end\n")
  p("  "..class_name..".__reset(self)\n")
else -- slow
  p("  local self={}\n")
  for i,v in pairs(function_names) do
    p("  self."..v.."="..class_name.."."..v.."\n")
  end
  for i,v in pairs(collection_names) do
    p("  self._"..v.."s={}\n")
    p("  self.add"..firstToUpper(v).."="..class_name..".add"..firstToUpper(v).."\n")
    p("  self.remove"..firstToUpper(v).."="..class_name..".remove"..firstToUpper(v).."\n")
    p("  self.get"..firstToUpper(v).."s="..class_name..".get"..firstToUpper(v).."s\n")
  end
  for i,v in pairs(variable_names) do
    p("  self._"..v.."=nil --init\n")
    p("  self.get"..firstToUpper(v).."="..class_name..".get"..firstToUpper(v).."\n")
    p("  self.set"..firstToUpper(v).."="..class_name..".set"..firstToUpper(v).."\n")
  end
end
p("  return self\n")
p("end\n\n")

-- VARIABLE GET/SET
for i,v in pairs(variable_names) do
  p("function "..class_name..":get"..firstToUpper(v).."()\n")
  p("  return self._"..v.."\n")
  p("end\n\n")

  p("function "..class_name..":set"..firstToUpper(v).."(val)\n")
  p("  self._"..v.."=val\n")
  p("end\n\n")
end

-- COLLECTION ADD/REMOVE/GETS
for i,v in pairs(collection_names) do
  p("function "..class_name..":get"..firstToUpper(v).."s()\n")
  p("  assert(not self._"..v.."s_dirty,\"Error: collection `self._"..v.."s` is dirty.\")\n")
  p("  return self._"..v.."s\n")
  p("end\n\n")

  p("function "..class_name..":remove"..firstToUpper(v).."(val)\n")
  p("  if val == nil then\n")
  p("    for i,v in pairs(self._"..v.."s) do\n")
  p("      if v._remove then\n")
  p("        table.remove(self._"..v.."s,i)\n")
  p("      end\n")
  p("    end\n")
  p("    self._"..v.."s_dirty=nil\n")
  p("  else\n")
  p("    local found = false\n")
  p("    for i,v in pairs(self._"..v.."s) do\n")
  p("      if v == val then\n")
  p("        found = true\n")
  p("        break\n")
  p("      end\n")
  p("    end\n")
  p("    assert(found,\"Error: collection `self._"..v.."s` does not contain `val`\")\n")
  p("    val._remove=true\n")
  p("    self._"..v.."s_dirty=true\n")
  p("  end\n")
  p("end\n\n")

  p("function "..class_name..":add"..firstToUpper(v).."(val)\n")
  p("  assert(type(val)==\"table\",\"Error: collection `self._"..v.."s` can only add `table`\")\n")
  p("  table.insert(self._"..v.."s,val)\n")
  p("end\n\n")
end

if fast then
  -- POOLS
  p(class_name..".__dead_pool = {}\n")
  p(class_name..".__dead_pool_max = "..dead_pool_max.."\n")
  p(class_name..".__live_pool = {}\n\n")

  -- RESET
  p("function "..class_name..".__reset(self)\n")
  for i,v in pairs(collection_names) do
    p("  self._"..v.."s={}\n")
  end
  for i,v in pairs(variable_names) do
    p("  self._"..v.."=nil --init\n")
  end
  p("end\n\n")

  -- DESTROY
  p("function "..class_name..":destroy()\n")
  p("  for index,obj in pairs("..class_name..".__live_pool) do\n")
  p("    if obj == self then\n")
  p("      if #"..class_name..".__dead_pool < "..class_name..".__dead_pool_max then\n")
  p("        table.insert("..class_name..".__dead_pool,\n")
  p("          table.remove("..class_name..".__live_pool,index))\n")
  p("      else\n")
  p("        table.remove("..class_name..".__live_pool,index)\n")
  p("      end\n")
  p("      return true -- object has been marked as dead\n")
  p("    end\n")
  p("  end\n")
  p("  return false -- object was not in live_pool\n")
  p("end\n\n")
end

-- RETURN CLASS OBJECT
p("return "..class_name.."\n")

file_name = class_name.."class.lua"
file = io.open(file_name,"w")
file:write(s)
file:close()

io.write("File written to `"..file_name.."`\n")

#!/usr/bin/env luajit
local json = require "lib.dkjson"
math.randomseed(os.time())

local load_json = function(file_name)
  local file, error_message = io.open(file_name, "r")
  assert(file, error_message)
  local result = json.decode(file:read("*all"))
  file:close()
  return result
end

local save_json = function(file_name, data)
  local file, error_message = io.open(file_name, "w")
  assert(file, error_message)
  file:write(json.encode(data, { indent = true, }))
  file:write("\n")
  file:close()
end

local random_order = function(array)
  local temporary, order = {}, {}
  for i = 1, #array do
    temporary[i] = i
  end
  while next(temporary) do
    order[#order + 1] = table.remove(temporary, math.random(1, #temporary))
  end
  return order
end

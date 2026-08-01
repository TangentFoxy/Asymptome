#!/usr/bin/env luajit
local json = require "lib.dkjson"
math.randomseed(os.time())

local default_file = "books.json"

local path_exists = function(path_name)
  local file = io.open(path_name, "r")
  if file then
    file:close()
    return true
  end
  return false
end

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

local get_random_order = function(array)
  local temporary, order = {}, {}
  for i = 1, #array do
    temporary[i] = i
  end
  while next(temporary) do
    order[#order + 1] = table.remove(temporary, math.random(1, #temporary))
  end
  return order
end

local filters = {
  all_books = function(book)
    if book.hidden then return false end
    return true
  end,
  unread = function(book)
    if book.hidden then return false end
    if book.progress == 0 then
      return true
    end
    return false
  end,
  read = function(book)
    if book.hidden then return false end
    if book.progress == 1 then
      return true
    end
    return false
  end,
  in_progress = function(book)
    if book.hidden then return false end
    if book.progress > 0 and book.progress < 1 then
      return true
    end
    return false
  end,
}

local sort_orders
sort_orders = {
  most_progress = function(A, B)
    return A.progress > B.progress
  end,
  least_progress = function(A, B)
    return A.progress < B.progress
  end,
  highest_priority = function(A, B)
    return A.priority > B.priority
  end,
  lowest_priority = function(A, B)
    return A.priority < B.priority
  end,
  most_pages_remaining = function(A, B)
    if not (A.pages and B.pages) then -- if pages is unknown for both, fallback to percentage
      return A.progress > B.progress
    end
    local average_page_count = data.total_pages / #data.books
    local a = (A.pages or average_page_count) - (A.pages or average_page_count) * A.progress
    local b = (B.pages or average_page_count) - (B.pages or average_page_count) * B.progress
    return a > b
  end,
  fewest_pages_remaining = function(A, B)
    return not sort_orders.most_pages_remaining(A, B)
  end,
}

local data
if path_exists(default_file) then
  data = load_json(default_file)
  -- TODO verify data structure
else
  data = {
    books = {},
    elo = {
      distance_constant = 5,
      maximum_change = 2.5,
    },
    total_pages = 0,
    defaults = {
      launch = {
        filter = "in_progress",
        sort = "fewest_pages_remaining",
      },
    },
  }
end

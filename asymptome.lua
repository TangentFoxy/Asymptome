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
  exclude_series = function(book)
    if book.hidden then return false end
    if book.series and not (book.title or book.author) then
      return false
    end
    return true
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
      return A.progress < B.progress
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

local import_json = function(file_name)
  import = load_json(file_name)
  if import.books then

    for i = 1, #import.books do
      data.books[#data.books + 1] = import.books[i]
      -- TODO detect and ignore duplicates (would be better to provide user an option for what to do with duplicates)
      --  default should accept highest progress of duplicates?
    end

  else -- assume we are importing from decider.lua's format
    for title, value in pairs(import) do
      local run = function()
        local book = { -- minimum required book data strucutre
          priority = 0,
          progress = 0,
        }

        local i = title:find(" %(.-series.-%)")
        if i then
          book.series = title:sub(1, i - 1)
        end
        local i = title:find(" %(trilogy%)")
        if i then
          book.series = title:sub(1, i - 1)
        end
        local i = title:find(" %(.-author%)")
        if i then
          book.author = title:sub(1, i - 1)
        end
        local i = title:find(" %(genre%)")
        if i then
          print("Skipping import of \"" .. title .. "\"")
          return false
        end

        if not (book.series or book.author) then
          -- TODO detect " by " and split if needed
          book.title = title
        end

        if type(value) == "number" then
          book.priority = value

        else
          book.priority = value.score

          if value.done == true then
            book.progress = 1
          elseif value.done == false then
            book.hidden = true
          end
        end

        -- TODO detect duplicates before adding them
        data.books[#data.books + 1] = book
      end
      run()
    end
  end

  save_json(default_file, data)
end

local get_display_name = function(book)
  local result = ""

  if book.title then
    result = book.title
    if book.author then
      result = result .. " by " .. book.author
    end
  elseif book.author then
    result = book.author .. " (author)"
  end

  if book.series then
    if #result > 0 then
      result = result .. " (" .. book.series .. ")"
    else
      result = book.series .. " (series)"
    end
  end

  if book.genre then
    if #result > 0 then
      result = result .. " (" .. book.genre .. ")"
    else
      result = book.genre .. " (genre)"
    end
  end

  if book.pages then
    result = result .. " ~" .. math.floor(book.progress * book.pages) .. "/" .. book.pages .. " pages read"
  elseif book.progress > 0 and book.progress < 1 then
    result = result .. " ~" .. math.floor(book.progress * 100) .. "% read"
  end

  return result
end



local data
local launch = function()
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
    save_json(default_file, data)
  end

  -- TODO this probably needs to be its own function
  --       allowing selecting different presets/etc instead of just launch
  local selected_books = {}
  for i = 1, #data.books do
    local book = data.books[i]
    if filters[data.defaults.launch.filter](book) then
      selected_books[#selected_books + 1] = book
    end
  end
  table.sort(selected_books, sort_orders[data.defaults.launch.sort])

  return selected_books
end

local main = function(selected_books)
  for i = 1, math.min(10, #selected_books) do
    local book = selected_books[i]
    print("  " .. (i == 10 and "0" or i) .. ". " .. get_display_name(book))
  end
  print("Commands: " .. (#selected_books > 0 and "[0-9] to modify a book's progress. " or "") .. "[i <file>] to import from a JSON file. Control+C to exit.")
  print("  Adding/Selecting: Title OR Title by Author OR \"Name (type)\" for other types.")
  -- TODO define what can go in <book> and how it will be interpreted
  -- TODO actually implement modifying progress and adding books
  -- TODO implement elo ranking
  -- TODO type title to add or edit an extant book (this is better than the "a" command I wrote above)

  local input = io.read("*line")

  if input:sub(1, 1) == "i" then
    import_json(input:sub(3))
  end
end

local selected_books = launch()
while true do
  main(selected_books)
end

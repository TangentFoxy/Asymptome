#!/usr/bin/env luajit
local json = require "lib.dkjson"
math.randomseed(os.time())

local default_file = "books.json"
local debug = function() end
-- local debug = function(...) print(...) end

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
  debug("Saved.")
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
  most_pages_remaining = function(A, B, data)
    if not (A.pages and B.pages) then -- if pages is unknown for both, fallback to percentage
      return A.progress < B.progress
    end
    local average_page_count = data.total_pages / data.books_with_page_count
    if not (average_page_count == average_page_count) then
      average_page_count = 300 -- based on average novel length
    end
    local a = (A.pages or average_page_count) - (A.pages or average_page_count) * A.progress
    local b = (B.pages or average_page_count) - (B.pages or average_page_count) * B.progress
    return a > b
  end,
  fewest_pages_remaining = function(A, B, data)
    return not sort_orders.most_pages_remaining(A, B, data)
  end,
}

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

local update_progress_prompt = function(book)
  if not book then
    print("Invalid selection.")
    return false
  end

  print("Enter a value between 0 and 1 to update progress:")
  print("  " .. get_display_name(book))

  local input = io.read("*line")
  local numerical = tonumber(input)
  if numerical >= 0 and numerical <= 1 then
    book.progress = numerical
    return true
  end

  -- saving is handled by a higher function on the stack
end

local detect_type = function(input)
  local author, series, genre
  local i = input:find(" %(.-series.-%)")
  if i then
    series = input:sub(1, i - 1)
  end
  local i = input:find(" %(trilogy%)")
  if i then
    series = input:sub(1, i - 1)
  end
  local i = input:find(" %(.-author%)")
  if i then
    author = input:sub(1, i - 1)
  end
  local i = input:find(" %(genre%)")
  if i then
    genre = input:sub(1, i - 1)
  end
  return author, series, genre
end

local get_book = function(data, input)
  local title, author, series, genre
  local i, j = input:find(" by ")
  if i then
    title = input:sub(1, i - 1)
    author = input:sub(j + 1)
    debug("get_book() Title by Author detected:", title, author)
  else
    author, series, genre = detect_type(input)

    if not (author or series or genre) then
      title = input
    end
  end

  local book
  for i = 1, #data.books do
    local current = data.books[i]
    if title then
      if current.title == title then
        if author then
          if current.author and current.author == author then
            book = current
            break
          end
        else
          book = current
          break
        end
      end
    elseif author and current.author == author then
      book = current
      break
    elseif series and current.series == series then
      book = current
      break
    elseif genre and current.genre == genre then
      book = current
      break
    end
  end

  if not book then
    book = {
      title = title,
      author = author,
      series = series,
      genre = genre,
      progress = 0,
      priority = math.random(),
    }
    data.books[#data.books + 1] = book
  end

  -- this may or may not stay relevant to this placement
  return update_progress_prompt(book)
end

local update_book = function(book)
  -- currently just a wrapper, because I'm not sure if this will stay exactly consistent with that
  return update_progress_prompt(book)
end

local book_exists = function(data, book)
  for i = 1, #data.books do
    local current = data.books[i]
    if not (book.title == current.title) then
      break
    end
    if not (book.author == current.author) then
      break
    end
    if not (book.series == current.series) then
      break
    end
    if not (book.genre == current.genre) then
      break
    end
    return current -- we return the object instead of true so it can be updated if desired
  end
  return false
end

local recalculate_total_pages = function(data)
  data.total_pages = 0
  data.books_with_page_count = 0
  for i = 1, #data.books do
    local book = data.books[i]
    if book.pages then
      data.total_pages = data.total_pages + book.pages
      data.books_with_page_count = data.books_with_page_count + 1
    end
  end
end

local import_json = function(data, file_name)
  import = load_json(file_name)
  if import.books then

    for i = 1, #import.books do
      -- TODO allow updating metadata instead of just ignoring
      if not book_exists(data, import.books[i]) then
        data.books[#data.books + 1] = import.books[i]
      end
    end

  else -- assume we are importing from decider.lua's format
    for title, value in pairs(import) do
      local run = function()
        local book = { -- minimum required book data strucutre
          priority = math.random(),
          progress = 0,
        }

        book.author, book.series, book.genre = detect_type(title)

        if not (book.series or book.author or book.genre) then
          local i, j = title:find(" by ")
          if i then
            book.title = title:sub(1, i - 1)
            book.author = title:sub(j + 1)
          else
            book.title = title
          end
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

        -- TODO allow updating metadata (this and the above need to be split into its own function)
        if not book_exists(data, book) then
          data.books[#data.books + 1] = book
        end
      end
      run()
    end
  end

  recalculate_total_pages(data)
  -- we must rely on parent function to save
end



local prep_sort_function = function(data, sort_function)
  -- this allows me to pass data as a third argument for functions that use it
  return function(A, B)
    return sort_function(A, B, data)
  end
end

local get_books_by_preset = function(data, preset_name)
  local selected_books = {}
  for i = 1, #data.books do
    local book = data.books[i]
    if filters[data.defaults[preset_name].filter](book) then
      selected_books[#selected_books + 1] = book
    end
  end
  table.sort(selected_books, prep_sort_function(sort_orders[data.defaults[preset_name].sort], data))
  return selected_books
end

local print_list = function(data, options)
  local gsplit = function(s, delimiter)
    local function escape_special_characters(s)
      local special_characters = "[()%%.[^$%]*+%-?]"
      if s == nil then return end
      return (s:gsub(special_characters, "%%%1"))
    end

    delimiter = delimiter or ","
    if s:sub(-#delimiter) ~= delimiter then s = s .. delimiter end
    return s:gmatch("(.-)" .. escape_special_characters(delimiter))
  end
  local split = function(s, delimiter)
    local result = {}
    for item in gsplit(s, delimiter) do
      result[#result + 1] = item
    end
    return result
  end

  options = split(options, " ")

  local selected_books = {}
  for i = 1, #data.books do
    local book = data.books[i]
    if filters[options[1]](book) then
      selected_books[#selected_books + 1] = book
    end
  end
  table.sort(selected_books, prep_sort_function(sort_orders[options[2]], data))

  local limit = 10
  if options[3] == "all" then
    limit = #selected_books
  end

  print("")
  for i = 1, limit do
    local book = selected_books[i]
    print(i .. ". " .. get_display_name(book))
  end

  print("  Press enter to continue.")
  io.read("*line")
end

local launch = function(file_name)
  local data
  if path_exists(file_name) then
    data = load_json(file_name)
    -- TODO verify data structure
    if not data.books_with_page_count then
      recalculate_total_pages(data)
    end
  else
    data = {
      books = {},
      elo = {
        distance_constant = 5,
        maximum_change = 2.5,
      },
      total_pages = 0,
      books_with_page_count = 0,
      defaults = {
        launch = {
          filter = "in_progress",
          sort = "fewest_pages_remaining",
        },
      },
    }
    save_json(file_name, data)
  end

  local selected_books = get_books_by_preset(data, "launch")

  return data, selected_books
end

local main = function(data, selected_books)
  for i = 1, math.min(10, #selected_books) do
    local book = selected_books[i]
    print("  " .. (i == 10 and "0" or i) .. ". " .. get_display_name(book))
  end
  print("Commands: " .. (#selected_books > 0 and "[0-9] to modify a book's progress. " or "") .. "[i <file>] to import from a JSON")
  print("          file. [recalculate pages] Enter nothing to exit.")
  print("  Adding/Selecting: Title OR Title by Author OR \"Name (type)\" for other types.")
  print("  Listing: list [filter] [sort] (all)")
  -- TODO implement elo ranking

  local input = io.read("*line")
  local numerical = tonumber(input)

  if #input == 0 then
    os.exit(0)
  elseif numerical and (numerical >= 0 and numerical <= 9) then
    update_book(selected_books[numerical])
  elseif input:sub(1, 1) == "i" then
    import_json(data, input:sub(3))
  elseif input:find("list ") == 1 then
    print_list(data, input:sub(6))
    return true
  elseif input:find("recalculate pages") == 1 then
    recalculate_total_pages(data)
  else -- assume we are trying to add/select a book
    get_book(data, input)
    -- but that just returns a book, we need to DO something with it ??
    -- right now, it demands a progress update;
    -- TODO add mode selection to select and update vs select only mode that THEN asks what to do?
    --       no? these are completely separate modes, there should be quick add, update progress, rank mode, add pages mode, etc
  end

  save_json(default_file, data) -- this assumes it is equivalent with how launch() is called
  return true
end

local data, selected_books = launch(default_file) -- the file name doesn't make it to main :\
while true do
  main(data, selected_books)
end

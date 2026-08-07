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
  audiobooks_only = function(book)
    if book.hidden then return false end
    if book.hours then
      return true
    end
    return false
  end,
}

return filters

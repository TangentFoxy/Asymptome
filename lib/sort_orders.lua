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
  most_time_remaining = function(A, B)
    if not (A.hours and B.hours) then -- fallback to percentage
      return A.progress < B.progress
    end
    local a = A.hours - A.hours * A.progress
    local b = B.hours - B.hours * B.progress
    return a > b
  end,
  least_time_remaining = function(A, B)
    return not sort_orders.most_time_remaining(A, B)
  end,
}

return sort_orders

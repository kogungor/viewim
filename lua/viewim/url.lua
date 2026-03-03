local M = {}

local function parse(value)
  if type(value) ~= "string" then
    return nil
  end

  local url = vim.trim(value)
  if url == "" then
    return nil
  end

  local scheme = url:match("^([%a][%w+.-]*)://")
  if not scheme then
    return nil
  end

  scheme = scheme:lower()
  return {
    raw = url,
    scheme = scheme,
  }
end

function M.is_http_url(value)
  local parsed = parse(value)
  if not parsed then
    return false
  end
  return parsed.scheme == "http" or parsed.scheme == "https"
end

function M.get_scheme(value)
  local parsed = parse(value)
  return parsed and parsed.scheme or nil
end

function M.extension_from_url(value)
  if type(value) ~= "string" then
    return nil
  end

  local no_query = value:match("^[^?#]+") or value
  local ext = no_query:match("(%.[a-zA-Z0-9]+)$")
  if not ext then
    return nil
  end

  return ext:lower()
end

return M

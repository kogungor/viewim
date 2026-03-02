local M = {}

--- Join non-empty lines into a single message.
--- @param lines string[]|nil
--- @return string
function M.join_nonempty(lines)
  if type(lines) ~= "table" then
    return ""
  end

  local acc = {}
  for _, line in ipairs(lines) do
    if line and line:match("%S") then
      table.insert(acc, line)
    end
  end
  return table.concat(acc, "\n")
end

return M

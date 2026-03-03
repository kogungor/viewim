local detect = require("viewim.detect")
local util = require("viewim.runners.util")

local M = {}

--- Check whether kitty internal rendering is likely available.
--- @return boolean,string|nil
function M.is_supported()
  if detect.get_terminal() ~= "kitty" then
    return false, "requires kitty terminal"
  end

  if detect.has_command("kitten") ~= true then
    return false, "'kitten' command not found in $PATH"
  end

  return true
end

--- Render image in current terminal using kitten icat placeholders.
--- @param path string
--- @return boolean,string|nil
function M.render(path)
  local cmd = {
    "kitten",
    "icat",
    "--unicode-placeholder",
    "--stdin=no",
    "--transfer-mode=stream",
    path,
  }

  local stdout_buf = {}
  local stderr_buf = {}
  local done = false
  local ok = false
  local err_msg = nil

  local job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if type(data) == "table" then
        vim.list_extend(stdout_buf, data)
      end
    end,
    on_stderr = function(_, data)
      if type(data) == "table" then
        vim.list_extend(stderr_buf, data)
      end
    end,
    on_exit = function(_, code)
      if code ~= 0 then
        local msg = util.join_nonempty(stderr_buf)
        if msg == "" then
          msg = "kitten icat exited with code " .. code
        end
        ok = false
        err_msg = msg
        done = true
        return
      end

      local output = util.join_nonempty(stdout_buf)
      if output ~= "" then
        vim.schedule(function()
          vim.api.nvim_out_write(output .. "\n")
        end)
      end

      ok = true
      done = true
    end,
  })

  if job_id <= 0 then
    return false, "failed to start kitten icat job"
  end

  local wait_result = vim.fn.jobwait({ job_id }, 5000)
  if wait_result[1] == -1 then
    vim.fn.jobstop(job_id)
    return false, "kitten icat timed out"
  end

  if not done then
    return false, "kitten icat did not complete"
  end

  return ok, err_msg
end

return M

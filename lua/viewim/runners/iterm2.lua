local util = require("viewim.runners.util")
local notify = require("viewim.notify")

local M = {}

local IMGCAT_PATHS = {
  "imgcat",
  "/usr/local/bin/imgcat",
  vim.fn.expand("~") .. "/.iterm2/imgcat",
}

local function find_imgcat()
  for _, p in ipairs(IMGCAT_PATHS) do
    if vim.fn.executable(p) == 1 then
      return p
    end
  end
  return nil
end

--- Check whether iTerm2 imgcat rendering is available.
--- @return boolean,string|nil
function M.is_supported()
  if
    (os.getenv("TERM_PROGRAM") or "") ~= "iTerm.app" and not (require("viewim.config").options or {}).force_terminal
  then
    return false, "requires iTerm2 terminal"
  end

  local imgcat = find_imgcat()
  if not imgcat then
    return false, "'imgcat' not found — install via iTerm2 shell integration or brew"
  end

  return true
end

--- Render image inline using iTerm2 imgcat.
--- @param path string
--- @return boolean,string|nil
function M.run(path, _opts)
  local imgcat = find_imgcat()
  if not imgcat then
    return false, "viewim: 'imgcat' not found in $PATH"
  end

  local stdout_buf = {}
  local stderr_buf = {}
  local done = false
  local ok = false
  local err_msg = nil

  local job_id = vim.fn.jobstart({ imgcat, "--", path }, {
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
          msg = "imgcat exited with code " .. code
        end
        ok = false
        err_msg = "viewim: iTerm2 imgcat error: " .. msg
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
    return false, "viewim: failed to start imgcat job"
  end

  local completed = vim.wait(5000, function()
    return done
  end, 10)

  if not completed then
    vim.fn.jobstop(job_id)
    return false, "viewim: imgcat timed out"
  end

  if not ok and err_msg then
    notify.error(err_msg)
  end

  return ok, err_msg
end

return M

local path = require("viewim.path")
local url = require("viewim.url")

local M = {}

local MIME_EXTENSION_MAP = {
  ["image/apng"] = ".png",
  ["image/avif"] = ".avif",
  ["image/bmp"] = ".bmp",
  ["image/gif"] = ".gif",
  ["image/jpeg"] = ".jpg",
  ["image/jpg"] = ".jpg",
  ["image/png"] = ".png",
  ["image/webp"] = ".webp",
}

local function parse_content_type(header_lines)
  local content_type = nil
  for _, line in ipairs(header_lines) do
    local value = line:match("^[Cc]ontent%-[Tt]ype:%s*([^;]+)")
    if value then
      content_type = vim.trim(value):lower()
    end
  end
  return content_type
end

local function ensure_cache_dir(cache_dir)
  if vim.fn.isdirectory(cache_dir) == 1 then
    return true
  end

  local ok = vim.fn.mkdir(cache_dir, "p") == 1
  if ok then
    return true
  end

  return false
end

local function make_target_path(cache_dir, source_url)
  local ext = url.extension_from_url(source_url)
  local hash = vim.fn.sha256(source_url)
  return cache_dir .. "/" .. hash .. (ext or ".img")
end

local function maybe_apply_content_type_extension(target_path, content_type)
  local ext = MIME_EXTENSION_MAP[content_type]
  if not ext then
    return target_path
  end

  if target_path:sub(-#ext) == ext then
    return target_path
  end

  local renamed = target_path:gsub("%.[a-zA-Z0-9]+$", "") .. ext
  if vim.fn.rename(target_path, renamed) == 0 then
    return renamed
  end

  return target_path
end

--- Download a remote image URL to the local cache.
--- @param source_url string
--- @param opts table
--- @param callback fun(path:string|nil, meta:table|nil, err:string|nil)
function M.fetch(source_url, opts, callback)
  opts = opts or {}
  local cache_dir = opts.cache_dir

  if not cache_dir or cache_dir == "" then
    callback(nil, nil, "viewim: remote cache_dir is not configured")
    return
  end

  if not ensure_cache_dir(cache_dir) then
    callback(nil, nil, "viewim: failed to create cache dir: " .. cache_dir)
    return
  end

  local target_path = make_target_path(cache_dir, source_url)
  if path.has_control_chars(target_path) then
    callback(nil, nil, "viewim: rejected cache path with control characters")
    return
  end

  local timeout_seconds = math.max(1, math.floor((opts.timeout_ms or 10000) / 1000))
  local max_filesize = tostring(opts.max_bytes or 10485760)

  local header_lines = {}
  local stderr_lines = {}
  local cmd = {
    "curl",
    "--location",
    "--fail",
    "--silent",
    "--show-error",
    "--max-time",
    tostring(timeout_seconds),
    "--max-filesize",
    max_filesize,
    "--proto",
    "=http,https",
    "--proto-redir",
    "=http,https",
    "--dump-header",
    "-",
    "--output",
    target_path,
    source_url,
  }

  local job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if type(data) == "table" then
        vim.list_extend(header_lines, data)
      end
    end,
    on_stderr = function(_, data)
      if type(data) == "table" then
        vim.list_extend(stderr_lines, data)
      end
    end,
    on_exit = function(_, code)
      if code ~= 0 then
        vim.fn.delete(target_path)
        local stderr_msg = table.concat(
          vim.tbl_filter(function(v)
            return v and v ~= ""
          end, stderr_lines),
          "\n"
        )
        local msg = stderr_msg ~= "" and stderr_msg or ("curl exited with code " .. code)
        callback(nil, nil, "viewim: remote download failed: " .. msg)
        return
      end

      local content_type = parse_content_type(header_lines)
      local final_path = maybe_apply_content_type_extension(target_path, content_type)
      callback(final_path, { content_type = content_type }, nil)
    end,
  })

  if job_id <= 0 then
    callback(nil, nil, "viewim: failed to start curl download")
  end
end

--- Clean the remote image cache by removing files older than max_age_days
--- and trimming total size to max_cache_bytes (oldest-first).
--- @param opts table remote config options
--- @param callback fun(removed:integer, freed_bytes:integer, err:string|nil)
function M.clean_cache(opts, callback)
  opts = opts or {}
  local cache_dir = opts.cache_dir
  if not cache_dir or cache_dir == "" or vim.fn.isdirectory(cache_dir) ~= 1 then
    callback(0, 0, nil)
    return
  end

  local max_age_days = opts.max_age_days or 0
  local max_bytes = opts.max_cache_bytes or 0
  local now = os.time()
  local files = {}

  local handle = vim.uv.fs_scandir(cache_dir)
  if not handle then
    callback(0, 0, "viewim: cannot read cache dir: " .. cache_dir)
    return
  end

  while true do
    local name, ftype = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if ftype == "file" then
      local full = cache_dir .. "/" .. name
      local stat = vim.uv.fs_stat(full)
      if stat then
        table.insert(files, { path = full, mtime = stat.mtime.sec, size = stat.size })
      end
    end
  end

  table.sort(files, function(a, b)
    return a.mtime < b.mtime
  end)

  local removed = 0
  local freed = 0

  for _, f in ipairs(files) do
    local age_days = (now - f.mtime) / 86400
    if max_age_days > 0 and age_days > max_age_days then
      vim.fn.delete(f.path)
      removed = removed + 1
      freed = freed + f.size
      f.deleted = true
    end
  end

  if max_bytes > 0 then
    local total = 0
    for _, f in ipairs(files) do
      if not f.deleted then
        total = total + f.size
      end
    end
    for _, f in ipairs(files) do
      if not f.deleted and total > max_bytes then
        vim.fn.delete(f.path)
        total = total - f.size
        removed = removed + 1
        freed = freed + f.size
      end
    end
  end

  callback(removed, freed, nil)
end

return M

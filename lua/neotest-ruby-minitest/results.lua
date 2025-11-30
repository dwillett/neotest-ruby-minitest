local lib = require("neotest.lib")
local logger = require("neotest.logging")

local M = {}

-- If true, do not delete the JSON output file after reading it.
-- Useful for debugging.
M.keep_output = false

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result>
M.parse = function(spec, result, tree)
  local path = spec.context.json_path
  local success, output = pcall(lib.files.read, path)
  if not success then
    logger.error("neotest-ruby-minitest: could not read output: " .. output)
    return {}
  end

  if not M.keep_output then
    local err
    success, err = os.remove(path)
    if not success then
      logger.warn("neotest-ruby-minitest: could not remove output file: " .. err)
      return {}
    end
  end

  local decoded_ok, payload = pcall(vim.json.decode, output, {
    luanil = { object = true, array = true },
  })
  if not decoded_ok then
    logger.error("neotest-ruby-minitest: invalid JSON")
    return {}
  end

  local function classify_status(t)
    if t.skipped then return "skipped" end
    if t.error then return "failed" end
    if t.failures and #t.failures > 0 then return "failed" end
    return "passed"
  end

  local function failure_message(t)
    if t.error then return "error" end
    if not (t.failures and #t.failures > 0) then return "" end
    local parts = {}
    for _, f in ipairs(t.failures) do
      local head = (f.type or "failure")
      local msg = (f.message or "")
      table.insert(parts, head .. ": " .. msg)
      if f.backtrace and #f.backtrace > 0 then
        table.insert(parts, table.concat(f.backtrace, "\n"))
      end
    end
    return table.concat(parts, "\n\n")
  end

  -- Build a lookup table from (basename::class::name) -> neotest position ID
  -- This handles the case where Ruby's source_location returns a different path
  -- than what Neotest uses (e.g., relative vs absolute paths)
  local id_lookup = {}
  if tree then
    for _, node in tree:iter_nodes() do
      local data = node:data()
      if data and data.type == "test" and data.id then
        -- Extract class and test name from the neotest ID
        -- Format: /path/to/file.rb::ClassName::test_name
        local file_path, class_name, test_name = data.id:match("^(.+)::([^:]+)::([^:]+)$")
        if file_path and class_name and test_name then
          local basename = vim.fs.basename(file_path)
          local key = basename .. "::" .. class_name .. "::" .. test_name
          id_lookup[key] = data.id
        end
      end
    end
  end

  local results = {}
  local tests = payload.tests or {}
  for _, t in ipairs(tests) do
    -- Build the raw ID from JSON data
    local raw_id = t.file .. "::" .. t.class .. "::" .. t.name
    if not raw_id then
      vim.notify("neotest-ruby-minitest: test without id", vim.log.levels.WARN)
      return {}
    end

    -- Try to match against neotest position IDs using basename
    local id = raw_id
    if t.file and t.class and t.name then
      local basename = vim.fs.basename(t.file)
      local lookup_key = basename .. "::" .. t.class .. "::" .. t.name
      if id_lookup[lookup_key] then
        id = id_lookup[lookup_key]
      end
    end

    local status = classify_status(t)
    local long_msg = failure_message(t)
    local short_msg = (#long_msg > 0) and long_msg:sub(1, 200) or ""

    results[id] = {
      status = status,              -- "passed" | "failed" | "skipped"
      short = short_msg,            -- brief summary
      output = result.output,       -- path to the raw output (for quick open)
      location = (t.file and t.line) and (t.file .. ":" .. t.line) or nil,
      duration = t.time or 0,
      errors = t.failures,       -- optional; neotest will show details via output too
    }
  end

  return results
end

return M

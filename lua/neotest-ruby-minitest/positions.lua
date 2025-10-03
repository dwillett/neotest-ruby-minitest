local lib = require("neotest.lib")

local M = {}

local plain_query = [[
    (
      class
      name: (constant) @namespace.name
      (superclass (scope_resolution) @superclass (#match? @superclass "Test$"))
    ) @namespace.definition
    (
      method
      name: (identifier) @test.name (#match? @test.name "^test_")
    ) @test.definition
]]

-- Parses the given file with the plain query.
---@param file string
---@return neotest.Tree
local function plain(file)
  return lib.treesitter.parse_positions(file, plain_query, {
    nested_tests = true,
    require_namespaces = true,
    position_id = nil,
  })
end


local bare_query = [[
    (
     class
     name: (constant) @namespace.name
     (superclass
      [
        (scope_resolution) @superclass.fq
        (constant)         @superclass.name
      ]
     )
  ) @namespace.definition

  (
    method
    name: (identifier) @test.name (#match? @test.name "^test_")
  ) @test.definition
]]

-- Parses the given file with the bare query.
---@param file string
---@return neotest.Tree
local function bare(file)
  return lib.treesitter.parse_positions(file, bare_query, {
    nested_tests = true,
    require_namespaces = true,
    position_id = nil,
  })
end

local rails_query = [[
(class
  name: (constant) @namespace.name
  (superclass
    (scope_resolution
      name: (constant) @superclass.name (#any-of? @superclass.name "SystemTestCase" "TestCase" "IntegrationTest"))
    )
  ) @namespace.definition

(class
  name: (constant) @namespace.name
  (superclass
    (constant) @superclass.name (#match? @superclass.name "Test")
    )
  ) @namespace.definition

(class
  name: (scope_resolution) @namespace.name
  (superclass
    (constant) @superclass.name (#match? @superclass.name "Test")
    )
  ) @namespace.definition

(class
  name: (scope_resolution) @namespace.name
  (superclass
    (scope_resolution
      name: (constant) @superclass.name (#any-of? @superclass.name "SystemTestCase" "TestCase" "IntegrationTest"))
    )
  ) @namespace.definition

(call
  method: (identifier) @fname (#match? @fname "test")
  arguments: (argument_list
               (string ( string_content ) @test.name))
  ) @test.definition
]]

-- Parses the given file with the rails query.
---@param file string
---@return neotest.Tree
local function rails(file)
  return lib.treesitter.parse_positions(file, rails_query, {
    nested_tests = true,
    require_namespaces = true,
    position_id = nil,
  })
end

---@param tree neotest.Tree
---@return integer
local function count_nodes(tree)
  ---@param node neotest.Tree
  ---@return integer
  local function recurse(node)
    local n = 1
    if not node then
      return n
    end
    for _, child in ipairs(node:children()) do
      n = n + recurse(child)
    end
    return n
  end
  return recurse(tree)
end

-- Parses the given file and returns a tree of positions.
---@param file_path string
---@return neotest.Tree
M.discover_positions = function(file_path)
  if not vim.loop.fs_stat(file_path) then
    error("file does not exist: " .. file_path)
  end
  local nodes = {
    bare(file_path),
    plain(file_path),
    rails(file_path),
  }
  local best
  local nbest = -1
  for _, value in ipairs(nodes) do
    local cnodes = count_nodes(value)
    if nbest < cnodes then
      nbest = cnodes
      best = value
    end
  end
  return best
end

return M

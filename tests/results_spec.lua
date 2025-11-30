local results = require("neotest-ruby-minitest.results")
local path = require("plenary.path")
local async = require("nio.tests")
local utils = require("tests.commons")

local OUT_STUB = { output = "/dev/null/raw.txt" }

local function params(json_path)
  return { context = { json_path = json_path } }, OUT_STUB, nil
end

describe("results.parse", function()
  async.it("can't find a file", function()
    local spec = { context = { json_path = "/dev/null/missing.json" } }
    local result = { output = "/dev/null/raw.txt" }
    assert.are_same({}, results.parse(spec, result, nil))
  end)

  async.it("can't parse empty json", function()
    utils.with_temp_dir(function(dir)
      local json_path = dir .. "/results.json"
      local res = results.parse(params(json_path))
      assert.are_same({}, res)
    end)
  end)

  async.it("can't parse ivalid json", function()
    utils.with_temp_dir(function(dir)
      local json_path = dir .. "/results.json"
      local content = "{ invalid json }"
      local file = io.open(json_path, "w")
      assert(file, "could not open file for writing: " .. json_path)
      file:write(content)
      file:close()
      local res = results.parse(params(json_path))
      assert.are_same({}, res)
    end)
  end)

  async.it("parses valid json output", function()
    utils.with_temp_dir(function(dir)
      local json_path = dir .. "/results.json"
      local from = utils.resource("json", "test_out.json")
      local to = path:new(json_path)
      utils.copy(from, to)
      local res = results.parse(params(json_path))
      assert.are_equal(63, vim.tbl_count(res))
    end)
  end)

  async.it("parses successful json output", function()
    utils.with_temp_dir(function(dir)
      local json_path = dir .. "/results.json"
      local from = utils.resource("json", "successful.json")
      local to = path:new(json_path)
      utils.copy(from, to)
      local res = results.parse(params(json_path))
      assert.are_equal(1, vim.tbl_count(res))
      local _, single = next(res)
      assert.are_equal("passed", single.status)
      assert.are_equal("", single.short)
      assert.are_equal("/dev/null/raw.txt", single.output)
      assert.are_equal(nil, single.localtion)
      assert.are_equal(0.00010799989104270935, single.duration)
      assert.are_same({}, single.errors)
    end)
  end)

  async.it("parses failed json output", function()
    utils.with_temp_dir(function(dir)
      local json_path = dir .. "/results.json"
      local from = utils.resource("json", "failure.json")
      local to = path:new(json_path)
      utils.copy(from, to)
      local res = results.parse(params(json_path))
      assert.are_equal(1, vim.tbl_count(res))
      local _, test = next(res)
      assert.no_nil(test)
      assert.are_equal("failed", test.status)
      assert.no_nil(test.short:find("Failure: [ foo: [42, 256] ].", 1, true))
      assert.no_nil(test.short:find("Expected: [43, 256]", 1, true))
      assert.no_nil(test.short:find("Actual: [42, 256]", 1, true))
      assert.are_equal("/dev/null/raw.txt", test.output)
      assert.are_equal(nil, test.localtion)
      assert.are_equal(0.00019100005738437175751, test.duration)
      assert.no_nil(test.errors[1])
    end)
  end)

  async.it("parses skipped json output", function()
    utils.with_temp_dir(function(dir)
      local json_path = dir .. "/results.json"
      local from = utils.resource("json", "skipped.json")
      local to = path:new(json_path)
      utils.copy(from, to)
      local res = results.parse(params(json_path))
      assert.are_equal(1, vim.tbl_count(res))
      local _, test = next(res)
      assert.no_nil(test)
      assert.are_equal("skipped", test.status)
      assert.no_nil(test.short:find("Skipped: Does not work", 1, true))
      assert.are_equal(nil, test.localtion)
      assert.are_equal(0.000022000051103532314, test.duration)
    end)
  end)

  async.it("removes the output file on parse by default", function()
    utils.with_temp_dir(function(dir)
      local json_path = dir .. "/results.json"
      local from = utils.resource("json", "successful.json")
      local to = path:new(json_path)
      utils.copy(from, to)
      results.parse(params(json_path))
      assert.is_false(path:new(json_path):exists())
    end)
  end)

  async.it("keeps the output file on parse", function()
    utils.with_temp_dir(function(dir)
      local json_path = dir .. "/results.json"
      local from = utils.resource("json", "successful.json")
      local to = path:new(json_path)
      utils.copy(from, to)
      local module = require("neotest-ruby-minitest.results")
      module.keep_output = true
      module.parse(params(json_path))
      assert.is_true(path:new(json_path):exists())
    end)
  end)

  async.it("sets the correct id", function()
    utils.with_temp_dir(function(dir)
      local json_path = dir .. "/results.json"
      local from = utils.resource("json", "successful.json")
      local to = path:new(json_path)
      utils.copy(from, to)
      local res = results.parse(params(json_path))
      assert.are_equal(1, vim.tbl_count(res))
      local id, _ = next(res)
      assert.are_equal("/test/factbase/terms/test_ordering.rb::TestOrdering::test_prev", id)
    end)
  end)

  async.it("maps results to neotest position IDs when tree is provided", function()
    utils.with_temp_dir(function(dir)
      local json_path = dir .. "/results.json"
      local from = utils.resource("json", "successful.json")
      local to = path:new(json_path)
      utils.copy(from, to)

      -- Create a mock tree with a test node that has a different absolute path
      -- but same basename/class/method as the JSON result
      local absolute_path = "/home/user/myproject/test/factbase/terms/test_ordering.rb"
      local expected_id = absolute_path .. "::TestOrdering::test_prev"
      local mock_tree = {
        iter_nodes = function()
          local nodes = {
            {
              data = function()
                return {
                  type = "test",
                  id = expected_id,
                }
              end
            }
          }
          local i = 0
          return function()
            i = i + 1
            if nodes[i] then
              return i, nodes[i]
            end
          end
        end
      }

      local spec = { context = { json_path = json_path } }
      local result_stub = { output = "/dev/null/raw.txt" }
      local res = results.parse(spec, result_stub, mock_tree)

      assert.are_equal(1, vim.tbl_count(res))
      local id, _ = next(res)
      -- The ID should now be the absolute path from the tree, not the relative path from JSON
      assert.are_equal(expected_id, id)
    end)
  end)

  async.it("normalizes module-prefixed class names and test_ prefixed method names", function()
    utils.with_temp_dir(function(dir)
      local json_path = dir .. "/results.json"
      -- Write a JSON file that mimics what Ruby outputs for Rails-style tests
      local json_content = [[{
        "summary": {"total": 1, "assertions": 1, "failures": 0, "errors": 0, "skips": 0, "duration": 0.01},
        "tests": [{
          "file": "/path/to/my_test.rb",
          "line": 10,
          "class": "MyModule::MyTestClass",
          "name": "test_#my_method_does_something",
          "time": 0.001,
          "assertions": 1,
          "failures": [],
          "skipped": false,
          "error": false
        }]
      }]]
      local file = io.open(json_path, "w")
      assert(file, "could not open file for writing: " .. json_path)
      file:write(json_content)
      file:close()

      -- Create a mock tree with the neotest-style ID (no module prefix, spaces in test name)
      local expected_id = "/absolute/path/to/my_test.rb::MyTestClass::#my method does something"
      local mock_tree = {
        iter_nodes = function()
          local nodes = {
            {
              data = function()
                return {
                  type = "test",
                  id = expected_id,
                }
              end
            }
          }
          local i = 0
          return function()
            i = i + 1
            if nodes[i] then
              return i, nodes[i]
            end
          end
        end
      }

      local spec = { context = { json_path = json_path } }
      local result_stub = { output = "/dev/null/raw.txt" }
      local res = results.parse(spec, result_stub, mock_tree)

      assert.are_equal(1, vim.tbl_count(res))
      local id, test_result = next(res)
      -- The ID should be the neotest ID, matched via normalization
      assert.are_equal(expected_id, id)
      assert.are_equal("passed", test_result.status)
    end)
  end)
end)

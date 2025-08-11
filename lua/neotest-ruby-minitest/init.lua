local RubyMinitestAdapter = {}

RubyMinitestAdapter.name = "neotest-ruby-minitest"

function RubyMinitestAdapter.is_test_file(path)
    return path:match("_test%.rb$") ~= nil or path:match("test_.+%.rb$") ~= nil
end

function RubyMinitestAdapter.filter_dir(name, rel_path, root)
    return not (name == "vendor" or name == ".git" or name == "node_modules" or name == "tmp")
end

function RubyMinitestAdapter.discover_positions(file_path)
end

function RubyMinitestAdapter.build_spec(args)
end

function RubyMinitestAdapter.results(spec, result, tree)
end

return RubyMinitestAdapter


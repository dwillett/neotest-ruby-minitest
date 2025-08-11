# neotest-ruby-minitest

A [minitest](https://docs.seattlerb.org/minitest/) adapter for [Neotest](https://github.com/nvim-neotest/neotest).

## Installation

Install using the package manager of your choice:

**Lazy**

```lua
{
  "nvim-neotest/neotest",
  lazy = true,
  dependencies = {
    ...,
    "volodya-lombrozo/neotest-ruby-minitest",
  },
  config = function()
    require("neotest").setup({
      ...,
      adapters = {
        require("neotest-ruby-minitest")
      },
    })
  end
}
```

## Configuration

### Default

```lua
adapters = {
  require("neotest-minitest")({
    command = function()
      return vim.tbl_flatten({
        "bundle",
        "exec",
        "ruby",
        "-Itest",
      })
    end,
  }),
}
```

You only need to add this configuration if you want to override the defaults. For example:

```lua
require("neotest-minitest")({
  test_cmd = function()
    return vim.tbl_flatten({
      "bundle",
      "exec",
      "rake",
      "test",
    })
  end
})
```

## How to Contribute

Fork the repository, make changes, and send a pull request. We will review your changes and merge them into the `main` branch if they meet our quality standards. 
To avoid delays, please ensure the full build passes before submitting your pull request:

```bash
todo
```

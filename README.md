# neotest-ruby-minitest

A [minitest](https://docs.seattlerb.org/minitest/) adapter for [Neotest](https://github.com/nvim-neotest/neotest).

## Installation

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
      return "ruby -Itest" 
    end
  }),
}
```

Usually, you don't need to modify the default configuration. However, if required, you can change 
the default command:

```lua
adapters = {
  require("neotest-minitest")({
    command = function()
      return "bundle exec ruby -Itest"
    end
  })
}
```

## How to Contribute

Fork the repository, make changes, and submit a pull request. We will review your changes and merge them into the `main` branch if they meet our quality standards. 
To avoid delays, please ensure that the entire build passes before submitting your pull request:

```bash
make test
make lint
```


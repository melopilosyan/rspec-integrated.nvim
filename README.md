# rspec-integrated.nvim

![rspec-integrated.nvim](https://user-images.githubusercontent.com/3795551/198903123-e935b51a-2725-488c-a517-19ef4dbeac88.png)

#### RSpec part
It runs `_spec.rb` files with `bundle exec rspec`.

#### Integrated part
It integrates test results back into `neovim` without forcing you to switch your attention away from the code.

It uses `neovim` core built-in features to seamlessly hook into your existing work flow.
* RSpec execution
  * Started/completed notifications: `vim.notify`
  * Asynchronous run: `vim.fn.jobstart`
* Test result presentation: `vim.diagnostics`

## Installation

[Neovim (v0.7.0)](https://github.com/neovim/neovim/releases/tag/v0.7.0) or higher is required.

Please refer to your plugin manager usage guide.

#### Example installing with [packer.nvim](https://github.com/wbthomason/packer.nvim)
```
use { "melopilosyan/rspec-integrated.nvim" }
```

## Usage
By default `rspec-integrated.nvim` doesn't add any mappings or create user commands. In fact, it will be auto-loaded only on the first invocation.

Add a mapping in your `neovim` configuration to call the exposed function. Sample mappings to `<leader>ti`:

```lua
-- Lua API
vim.keymap.set("n", "<leader>ti", "<cmd>lua require('rspec.integrated').run_spec_file()<cr>", { silent = true, noremap = true })
```

```vim
" VimL
nnoremap <leader>ti <cmd>lua require('rspec.integrated').run_spec_file()<cr>
```

## Configuration
The plugin has no configuration. You should be able to just say "RSpec run" and see the notifications as you have configured it or open/jump to diagnostic entries as you normally do with LSP or linter messages.

## Features
* Runs `rspec` for the entire spec file.
* Remembers the last spec file and can re-run it while in the production code buffer.
  Ideal during TDD and/or refactoring.
* Saves the current buffer before execution. One less action to keep in mind.

## Credits
Big shout-out to [@tjdevries](https://github.com/tjdevries) for the initial idea. Watch [his video tutorial](https://www.youtube.com/watch?v=cf72gMBrsI0), which was the inspiration for `rspec-integrated.nvim`.

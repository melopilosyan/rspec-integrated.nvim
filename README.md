# rspec-integrated.nvim

![rspec-integrated.nvim](https://user-images.githubusercontent.com/3795551/198903123-e935b51a-2725-488c-a517-19ef4dbeac88.png)

#### RSpec part
It runs `*_spec.rb` files with [RSpec](https://rspec.info/).

#### Integrated part
It integrates the test results back into Neovim. So you don't have to take your attention away from coding.

It makes use of Neovim's built-in features to integrate seamlessly into your existing workflow.

* RSpec execution
  * Started/completed notifications: `vim.notify`
  * Asynchronous run: `vim.fn.jobstart`
* Test result presentation: `vim.diagnostics`

## Features
* Runs RSpec test files.
* Executes a single test example determined by the cursor position.
* Remembers the last spec file and can re-run it while in the production code buffer. \
  Ideal during TDD and/or refactoring.
* Can repeat the last run on command.
* Has good intuition when selecting the RSpec execution command from the available defaults.
  1) `bin/rspec`
  2) `bundle exec rspec`
  3) `rspec`
* Saves open buffers before execution. One less action to keep in mind.
* Shows non-RSpec output of the test run with error messages. \
  Hint: Use `puts obj.pretty_inspect` to see it as it appears in the IRB console.

## Installation

At least [Neovim v0.7.0](https://github.com/neovim/neovim/releases) is required.

Please refer to the usage guide of your preferred plugin manager on how to install plugins.

##### With [packer.nvim](https://github.com/wbthomason/packer.nvim)
```
use { "melopilosyan/rspec-integrated.nvim" }
```

##### With [lazy.nvim](https://github.com/folke/lazy.nvim)
```
{ "melopilosyan/rspec-integrated.nvim", lazy = true }
```

## Usage
By default `rspec-integrated.nvim` doesn't add any mappings or create user commands. In fact, it will be auto-loaded only on the first invocation.

Add mappings in your `neovim` configuration to invoke the exposed function.

```lua
-- Lua API
local opts = { silent = true, noremap = true }
vim.keymap.set("n", "<leader>tI", "<cmd>lua require('rspec.integrated').run_spec_file()<cr>", opts)
vim.keymap.set("n", "<leader>ti", "<cmd>lua require('rspec.integrated').run_spec_file({only_current_example = true})<cr>", opts)
vim.keymap.set("n", "<leader>t.", "<cmd>lua require('rspec.integrated').run_spec_file({repeat_last_run = true})<cr>", opts)
```

```vim
" VimL
nnoremap <leader>tI <cmd>lua require('rspec.integrated').run_spec_file()<cr>
nnoremap <leader>ti <cmd>lua require('rspec.integrated').run_spec_file({only_current_example = true})<cr>
nnoremap <leader>t. <cmd>lua require('rspec.integrated').run_spec_file({repeat_last_run = true})<cr>
```

## Configuration
The plugin has no configuration. \
You should be able to just say “RSpec run” and see the notifications as you have configured them, or open/jump to diagnostic entries as you normally do with LSP or linter messages.

## Credits
Big shout-out to [@tjdevries](https://github.com/tjdevries) for the initial idea valuable lessons. Watch [his video tutorial](https://www.youtube.com/watch?v=cf72gMBrsI0), which was the inspiration for `rspec-integrated.nvim`.

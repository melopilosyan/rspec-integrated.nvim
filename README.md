# rspec-integrated.nvim

![Image showing test failure as a Neovim diagnostic entry](https://user-images.githubusercontent.com/3795551/198903123-e935b51a-2725-488c-a517-19ef4dbeac88.png)

![Image of multiple failed test files listed in the quickfix list](https://github.com/user-attachments/assets/621dfd32-0b1e-4e3c-85a0-a27ce47b3ec2)

#### RSpec part
It runs `*_spec.rb` files with [RSpec](https://rspec.info/).

#### Integrated part
It integrates the test results back into Neovim. So you don't have to take your attention away from coding.

It uses Neovim's built-in features to fit seamlessly into your existing workflow:
* `vim.notify` for notifications.
* `vim.diagnostics` or `quickfix list` for presentation of test failures.
* Terminal emulator for interactive debugging.

## Features
* Runs RSpec spec files individually, registering failures as Neovim diagnostic entries.
* Executes a single test example determined by the cursor position.
* Remembers the last spec file and can re-run it while in the production code buffer. \
  Ideal during TDD and/or refactoring.
* Can repeat the last run on command.
* Runs the test suite (except system tests), presenting failures as a quickfix list.
* Allows interactive debugging by running the nearest test example in the terminal.
* Has good intuition when choosing the RSpec execution command (in the following order of availability):
  1) `bin/rspec`
  2) `bundle exec rspec`
  3) `rspec`
* Resets the command when the current working directory changes.
* Saves open buffers before execution. (One less action to keep in mind.)
* Shows non-RSpec output with error messages. \
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
By default `rspec-integrated.nvim` doesn't add any mappings or create user commands.
In fact, it will be auto-loaded only on the first invocation.

Add mappings in your `neovim` configuration to invoke the exposed function.

```lua
-- Lua API
local opts = { silent = true, noremap = true }
vim.keymap.set("n", "<leader>tI", "<cmd>lua require('rspec.integrated').run()<cr>", opts)
vim.keymap.set("n", "<leader>ti", "<cmd>lua require('rspec.integrated').run({current_example = true})<cr>", opts)
vim.keymap.set("n", "<leader>t.", "<cmd>lua require('rspec.integrated').run({repeat_last_run = true})<cr>", opts)
vim.keymap.set("n", "<leader>td", "<cmd>lua require('rspec.integrated').run({debug = true})<cr>", opts)
vim.keymap.set("n", "<leader>tS", "<cmd>lua require('rspec.integrated').run({suite = true})<cr>", opts)
```

```vim
" VimL
nnoremap <leader>tI <cmd>lua require('rspec.integrated').run()<cr>
nnoremap <leader>ti <cmd>lua require('rspec.integrated').run({current_example = true})<cr>
nnoremap <leader>t. <cmd>lua require('rspec.integrated').run({repeat_last_run = true})<cr>
nnoremap <leader>td <cmd>lua require('rspec.integrated').run({debug = true})<cr>
nnoremap <leader>tS <cmd>lua require('rspec.integrated').run({suite = true})<cr>
```

## Configuration
The plugin has no configuration. \
You should be able to just say “RSpec run” and
display/jump to diagnostic entries as you normally do with LSP or linter messages,
or use quickfix list to navigate failures across multiple files.

Notifications designed to work with the [nvim-notify](https://github.com/rcarriga/nvim-notify) plugin.
But even without it, you'll still see the Neovim's default print lines,
or the look of the plugin assigned to `vim.notify`.

## Credit
Big shout-out to [@tjdevries](https://github.com/tjdevries) for the initial idea and
valuable lessons on how to run external commands from Neovim and integrate the output
back into the editor. Watch his video tutorial [Integrated Test Results in Neovim](https://www.youtube.com/watch?v=cf72gMBrsI0),
which was the inspiration for `rspec-integrated.nvim`.

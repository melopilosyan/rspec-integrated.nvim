# rspec-integrated.nvim

![rspec-integrated.nvim](https://user-images.githubusercontent.com/3795551/198903123-e935b51a-2725-488c-a517-19ef4dbeac88.png)

#### RSpec part
It runs `_spec.rb` files with `bundle exec rspec`.

#### Integrated part
It integrates the test results back into `neovim`. So you don't have to take your attention away from coding.

It uses the built-in `neovim` features to integrate seamlessly into your existing workflow.
* RSpec execution
  * Started/completed notifications: `vim.notify`
  * Asynchronous run: `vim.fn.jobstart`
* Test result presentation: `vim.diagnostics`

## Features
* Runs RSpec test files.
* Executes a single test example determined by the cursor position.
* Remembers the last spec file and can re-run it while in the production code buffer. \
  Ideal during TDD and/or refactoring.
* Saves the current buffer before execution. One less action to keep in mind.

## Installation

[Neovim version 0.7.0](https://github.com/neovim/neovim/releases/tag/v0.7.0) or higher is required.

Please refer to your plugin manager's usage guide.

##### Example installation with [packer.nvim](https://github.com/wbthomason/packer.nvim)
```
use { "melopilosyan/rspec-integrated.nvim" }
```

## Usage
By default `rspec-integrated.nvim` doesn't add any mappings or create user commands. In fact, it will be auto-loaded only on the first invocation.

Add mappings in your `neovim` configuration to invoke the exposed function.

```lua
-- Lua API
vim.keymap.set("n", "<leader>tI", "<cmd>lua require('rspec.integrated').run_spec_file()<cr>", { silent = true, noremap = true })
vim.keymap.set("n", "<leader>ti", "<cmd>lua require('rspec.integrated').run_spec_file({only_current_example = true})<cr>", { silent = true, noremap = true })
```

```vim
" VimL
nnoremap <leader>tI <cmd>lua require('rspec.integrated').run_spec_file()<cr>
nnoremap <leader>ti <cmd>lua require('rspec.integrated').run_spec_file({only_current_example = true})<cr>
```

## Configuration
The plugin has no configuration. You should be able to just say “RSpec run” and see the notifications as you have configured them, or open/jump to diagnostic entries as you normally do with LSP or linter messages.

## Credits
Big shout-out to [@tjdevries](https://github.com/tjdevries) for the initial idea. Watch [his video tutorial](https://www.youtube.com/watch?v=cf72gMBrsI0), which was the inspiration for `rspec-integrated.nvim`.

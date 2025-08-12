-- Set leader key BEFORE loading lazy.nvim
vim.g.mapleader = " "

-- Setup lazy.nvim
require("config.lazy")

-- General settings
vim.cmd("set encoding=utf-8")
vim.cmd("set title")
vim.opt.number = true
vim.opt.numberwidth = 3
vim.opt.wildmenu = true
vim.opt.wildmode = "full"
vim.opt.scrolloff = 5
vim.opt.lazyredraw = true
vim.opt.hidden = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.showmatch = true
vim.opt.showcmd = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.expandtab = true
vim.opt.signcolumn = "yes" -- for vim-gitgutter

-- markdown-preview
vim.g.mkdp_theme = "dark"


-- Keymaps
vim.keymap.set("v", "//", "y/<C-R>\"<CR>N")
vim.keymap.set("i", "<C-c>", "<Esc>")
vim.keymap.set("n", "Y", "y$")

vim.keymap.set("", ",,", ":e $MYVIMRC<cr>")
vim.keymap.set("", ",,,", ":source $MYVIMRC<cr>")

-- Movement in insert mode
vim.keymap.set("i", "<C-h>", "<C-o>h")
vim.keymap.set("i", "<C-l>", "<C-o>a")
vim.keymap.set("i", "<C-j>", "<C-o>j")
vim.keymap.set("i", "<C-k>", "<C-o>k")

-- Copy to clipboard
vim.keymap.set("v", "<C-c>", '"+y')

-- Buffers
vim.keymap.set("n", "<C-w>d", ":bp<CR>:bd#<CR>", { silent = true })
vim.keymap.set("n", "<C-w>D", ":%bd\\|e#<CR>", { silent = true })
vim.keymap.set("n", "<PageUp>", ":bprevious!<CR>", { silent = true })
vim.keymap.set("n", "<PageDown>", ":bnext!<CR>", { silent = true })

vim.keymap.set("n", "<leader>zz", ":!zed %:p<CR>")

-- Command aliases
vim.cmd([[
  command W w
  command Wq wq
  command WQ wq
  command Wqa wqa
  command WQA wqa
  command WQa wqa

  command Q q
  command Qa qa
  command QA qa

  command Bd bd
  command BD bd

  command TN tabnew
  command TC tabclose

  command! -nargs=0 Cwd :let @+ = expand('%:p')
]])

-- Load module configurations only when plugins are available
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyDone",
  callback = function()
    -- Only load modules after lazy.nvim has loaded all plugins
    local modules_path = vim.fn.stdpath("config") .. "/modules"
    local modules = vim.fn.globpath(modules_path, "*.vim", false, true)
    
    for _, module in ipairs(modules) do
      -- Skip loading modules that might conflict with lazy.nvim
      local module_name = vim.fn.fnamemodify(module, ":t:r")
      if not vim.tbl_contains({
        "autopairs", "avante", "conform", "diffview", "git-conflict",
        "kulala", "oil", "render-markdown", 
        "telescope", "treesitter", "ufo"
      }, module_name) then
        vim.cmd("source " .. module)
      end
    end
  end,
})
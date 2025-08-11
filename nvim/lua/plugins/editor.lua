return {
  {
    "tpope/vim-surround",
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-live-grep-args.nvim",
      "junegunn/fzf", 
    },
    config = function()
      local telescope = require('telescope')
      local telescopeConfig = require('telescope.config')
      local lga_actions = require('telescope-live-grep-args.actions')

      local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments)}

      table.insert(vimgrep_arguments, '--hidden')
      table.insert(vimgrep_arguments, '--glob')
      table.insert(vimgrep_arguments, '!.git/*')

      telescope.setup({
        defaults = {
          vimgrep_arguments = vimgrep_arguments,
          file_ignore_patterns = {
            "node_modules/",
          }
        },
        extensions = {
          live_grep_args = {
            auto_quoting = true,
            mappings = {
              i = {
                ['<C-k>'] = lga_actions.quote_prompt(),
              },
            },
          },
        },
        pickers = {
          find_files = {
            find_command = { 'rg', '--files', '--hidden', '--glob', '!.git/*' },
          },
        },
      })

      -- Keymaps
      vim.keymap.set("n", "<C-f>", "<cmd>lua require('telescope.builtin').find_files()<cr>", { nowait = true })
      vim.keymap.set("n", "<C-s>", "<cmd>lua require('telescope.builtin').find_files({ no_ignore = true })<cr>", { nowait = true })
      vim.keymap.set("n", "<C-g>", "<cmd>lua require('telescope').extensions.live_grep_args.live_grep_args()<cr>", { nowait = true })
      vim.keymap.set("n", "<C-b>", "<cmd>lua require('telescope.builtin').buffers()<cr>", { nowait = true })
    end,
  },
  {
    "nvim-telescope/telescope-live-grep-args.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      vim.cmd("source " .. vim.fn.stdpath("config") .. "/modules/autopairs.vim")
    end,
  },
  {
    "chaoren/vim-wordmotion",
    config = function()
      vim.cmd("source " .. vim.fn.stdpath("config") .. "/modules/vim-wordmotion.vim")
    end,
  },
  {
    "stevearc/oil.nvim",
    dependencies = { "kyazdani42/nvim-web-devicons" },
    config = function()
      vim.cmd("source " .. vim.fn.stdpath("config") .. "/modules/oil.vim")
    end,
  },
  {
    "lalitmee/browse.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
  },
  {
    "nanotee/zoxide.vim",
  },
  {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    config = function()
      vim.cmd("source " .. vim.fn.stdpath("config") .. "/modules/ufo.vim")
    end,
  },
  {
    "kevinhwang91/nvim-bqf",
  },
  {
    "kevinhwang91/promise-async",
  },
  {
    "chrisbra/csv.vim",
  },
  {
    "simnalamburt/vim-tiny-ime",
  },
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      vim.cmd("source " .. vim.fn.stdpath("config") .. "/modules/toggleterm.vim")
    end,
  },
  {
    "stevearc/dressing.nvim",
  },
  {
    "MunifTanjim/nui.nvim",
  },
  {
    "junegunn/fzf",
    build = function()
      vim.fn["fzf#install"]()
    end,
  },
  {
    "mhinz/vim-startify",
    config = function()
      vim.cmd("source " .. vim.fn.stdpath("config") .. "/modules/startify.vim")
    end,
  },
}
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
      require("nvim-autopairs").setup {}
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
      require('oil').setup({
        default_file_explorer = true,
        delete_to_trash = true,
        skip_confirm_for_simple_edits = true,
        view_options = {
          show_hidden = true,
          natural_order = true,
          is_always_hidden = function(name, _)
            return name == '..' or name == '.git'
          end,
        }
      })

      vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
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
      vim.o.foldcolumn = '1'
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true

      require('ufo').setup()
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
      require("toggleterm").setup({
        size = function(term)
          if term.direction == "horizontal" then
            return 20
          elseif term.direction == "vertical" then
            return vim.o.columns * 0.4
          end
        end,
        direction = 'vertical',
      })

      function _G.set_terminal_keymaps()
        local opts = {buffer = 0}
        vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
        vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
        vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
        vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
        vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
        vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
        vim.keymap.set('t', '<C-w>', [[<C-\><C-n><C-w>]], opts)
      end

      -- if you only want these mappings for toggle term use term://*toggleterm#* instead
      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "term://*",
        callback = function()
          set_terminal_keymaps()
        end,
      })
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
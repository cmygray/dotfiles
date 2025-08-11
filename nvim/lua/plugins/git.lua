return {
  {
    "tpope/vim-fugitive",
  },
  {
    "airblade/vim-gitgutter",
  },
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      vim.cmd("source " .. vim.fn.stdpath("config") .. "/modules/diffview.vim")
    end,
  },
  {
    "pwntester/octo.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "kyazdani42/nvim-web-devicons",
    },
    config = function()
      vim.cmd("source " .. vim.fn.stdpath("config") .. "/modules/octo.vim")
    end,
  },
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    config = function()
      vim.cmd("source " .. vim.fn.stdpath("config") .. "/modules/git-conflict.vim")
    end,
  },
  {
    "rhysd/conflict-marker.vim",
  },
  {
    "itchyny/vim-gitbranch",
  },
}
return {
  {
    "arcticicestudio/nord-vim",
    priority = 1000,
    config = function()
      vim.cmd("colorscheme nord")
    end,
  },
  {
    "rebelot/kanagawa.nvim",
    priority = 1000,
  },
  {
    "kyazdani42/nvim-web-devicons",
    opts = {},
  },
  {
    "itchyny/lightline.vim",
    config = function()
      -- Load lightline configuration from modules
      vim.cmd("source " .. vim.fn.stdpath("config") .. "/modules/lightline.vim")
    end,
  },
}
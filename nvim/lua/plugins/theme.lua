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
      vim.opt.laststatus = 2
      vim.opt.showmode = false

      vim.g.lightline = {
        colorscheme = 'nord',
      }
    end,
  },
}
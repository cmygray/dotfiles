return {
  {
    "rest-nvim/rest.nvim",
    tag = "0.2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      vim.cmd("source " .. vim.fn.stdpath("config") .. "/modules/rest.vim")
    end,
  },
  {
    "mistweaverco/kulala.nvim",
    config = function()
      vim.cmd("source " .. vim.fn.stdpath("config") .. "/modules/kulala.vim")
    end,
  },
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    branch = "main",
    build = "make",
    dependencies = {
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "kyazdani42/nvim-web-devicons",
      "MeanderingProgrammer/render-markdown.nvim",
    },
    config = function()
      vim.cmd("source " .. vim.fn.stdpath("config") .. "/modules/avante.vim")
    end,
  },
}
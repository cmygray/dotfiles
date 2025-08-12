return {
  {
    "jparise/vim-graphql",
  },
  {
    "rust-lang/rust.vim",
  },
  {
    "eliba2/vim-node-inspect",
  },
  {
    "wakatime/vim-wakatime",
  },
  {
    "iamcco/markdown-preview.nvim",
    build = "cd app; npx --yes yarn install",
    config = function()
      vim.cmd("source " .. vim.fn.stdpath("config") .. "/modules/markdown-preview.vim")
    end,
  },
  {
    "vimwiki/vimwiki",
    config = function()
      vim.cmd("source " .. vim.fn.stdpath("config") .. "/modules/wiki.vim")
    end,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    config = function()
      vim.cmd("source " .. vim.fn.stdpath("config") .. "/modules/render-markdown.vim")
    end,
  },
}
autocmd! User avante.nvim
lua << EOF
require('avante').setup({
  provider = 'gemini',
  auto_suggestions_provider = 'copilot',
  behavior = {
    auto_suggestions = true,
  },
  file_selector = {
    provider = "telescope",
  },
  gemini = {
    endpoint = "https://generativelanguage.googleapis.com/v1beta/models",
    model = "gemini-2.5-pro-exp-03-25",
    timeout = 30000,
    temperature = 0,
    max_tokens = 8192,
  }
})

vim.opt.laststatus = 3
EOF

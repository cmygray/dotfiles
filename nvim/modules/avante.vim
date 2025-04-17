autocmd! User avante.nvim
lua << EOF
require('avante').setup({
  provider = 'openrouter',
  vendors = {
    openrouter = {
      __inherited_from = 'openai',
      endpoint = 'https://openrouter.ai/api/v1',
      api_key_name = 'OPENROUTER_API_KEY',
      model = "google/gemini-2.5-pro-preview-03-25",
    },
  },
  behavior = {
    auto_suggestions = false,
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

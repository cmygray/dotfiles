autocmd! User avante.nvim
lua << EOF
require('avante').setup({
  provider = 'openrouter',
  providers = {
    openrouter = {
      __inherited_from = 'openai',
      endpoint = 'https://openrouter.ai/api/v1',
      api_key_name = 'OPENROUTER_API_KEY',
      model = "google/gemini-2.5-pro-preview-03-25",
    },
  },
  behavior = {
    auto_suggestions = true,
  },
  behavior = {
    auto_suggestions = true,
  },
  selector = {
    provider = "telescope",
  },
})

vim.opt.laststatus = 3
EOF

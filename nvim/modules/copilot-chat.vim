lua << EOF
require("CopilotChat").setup {
  debug = true, -- Enable debugging
  -- See Configuration section for rest
}
EOF

nnoremap <leader>ccq :lua require('CopilotChat').ask("", { selection = require("CopilotChat.select").buffer })<CR>


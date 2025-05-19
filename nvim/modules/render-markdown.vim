lua << EOF
require('render-markdown').setup({
  enabled = true,
  file_types = { 'markdown', 'vimwiki' },
})
EOF

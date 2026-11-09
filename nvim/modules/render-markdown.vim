lua << EOF
-- vimwiki 가 .md 를 filetype=vimwiki 로 잡는다. treesitter 에 vimwiki 언어가 없으면
-- render-markdown 이 파서를 못 얻어 아무것도 그리지 않으므로 markdown 파서로 연결한다.
vim.treesitter.language.register('markdown', 'vimwiki')

require('render-markdown').setup({
  enabled = true,
  file_types = { 'markdown', 'vimwiki' },
})
EOF

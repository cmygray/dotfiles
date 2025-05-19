let g:vimwiki_list = [
    \{
    \    'path': luaeval('vim.env.HOME') . '/Library/Mobile Documents/iCloud~md~obsidian/Documents/Wiki',
    \    'syntax': 'markdown',
    \    'ext': '.md'
    \}
\]

let g:vimwiki_global_ext = 0
let g:vimwiki_conceallevel = 0

nnoremap <LocalLeader>ws :execute "VWS /" . expand("<cword>") . "/" <Bar> :lopen<CR>
nnoremap <LocalLeader>wb :execute "VWB" <Bar> :lopen<CR>

let g:coc_global_extensions = [
      \'coc-tsserver',
      \'coc-json',
      \'coc-rust-analyzer',
      \'coc-prettier',
      \'coc-graphql',
      \'coc-yaml',
      \'coc-lua',
      \'coc-jest'
      \]

if has_key(g:plugs, 'coc.nvim')
  inoremap <silent><expr> <TAB>
        \ pumvisible() ? "\<C-n>" :
        \ <SID>check_back_space() ? "\<TAB>" :
        \ coc#refresh()
  inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
endif

nmap <silent> <A-Cr> <cmd>CocAction<cr>

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> Q :CocCommand prettier.formatFile<cr>

nmap <silent> <leader>r <Plug>(coc-rename)
nmap <silent> <leader>u <Plug>(coc-references)
nmap <silent> <leader>j <Plug>(coc-diagnostic-next)
nmap <silent> <leader>k <Plug>(coc-diagnostic-prev)
nmap <silent> <leader>R <cmd>CocCommand workspace.renameCurrentFile<cr>
"nmap <silent> <leader>j <Plug>(coc-diagnostic-next-error)
"nmap <silent> <leader>k <Plug>(coc-diagnostic-prev-error)


let g:coc_global_extensions = [
      \'coc-tsserver',
      \'coc-json',
      \'coc-rust-analyzer',
      \'coc-prettier',
      \'coc-yaml',
      \'coc-lua',
      \'coc-jest',
      \'coc-markdownlint',
      \'coc-python',
      \'coc-html',
      \'coc-sh'
      \]

inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1):
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo, please make your own choice.
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use K to show documentation in preview window.

function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

nmap <silent> <A-Cr> <Plug>(coc-codeaction-cursor)

" Goto
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gpd :call CocAction('jumpDefinition', v:false)<CR>
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gpi :call CocAction('jumpImplementation', v:false)<CR>
nmap <silent> gu <Plug>(coc-references)

nnoremap <silent> gr :call ShowDocumentation()<CR>

nmap <silent> <leader>j <Plug>(coc-diagnostic-next)
nmap <silent> <leader>k <Plug>(coc-diagnostic-prev)
nmap <silent> <leader>J <Plug>(coc-diagnostic-next-error)
nmap <silent> <leader>K <Plug>(coc-diagnostic-prev-error)

" Edit
"nmap <silent> Q :CocCommand prettier.formatFile<cr>
nmap <silent> <leader>r <Plug>(coc-rename)
nmap <silent> <leader>R <cmd>CocCommand workspace.renameCurrentFile<cr>

" let g:rustfmt_autosave = 1


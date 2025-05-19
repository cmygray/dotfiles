nmap \s :Startify<CR>
nmap \\s :SSave<CR>

let g:startify_list_order = [
            \ ['    Sessions'],
            \'sessions',
            \ ['    Most Recently Used files'],
            \'files',
            \'bookmarks',
            \ ['    Commands'],
            \'commands'
            \]

augroup vimstartify
    autocmd User Startified setlocal cursorline
augroup END

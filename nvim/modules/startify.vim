function! GetAutoSessionName()
  let path = substitute(getcwd(), $HOME, '', '')
  let path = substitute(path, '^/', '', '')
  let branch = gitbranch#name()
  let branch = empty(branch) ? '' : '@' . branch
  return substitute(path . branch, '/', '-', 'g')
endfunction

nmap \s :execute 'SSave! ' . GetAutoSessionName()<CR>
nmap \S :Startify<CR>
nmap \d :SDelete<CR>y<CR>

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
    autocmd SessionLoadPost * nested call timer_start(100, { -> execute('bufdo e')})


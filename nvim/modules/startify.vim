nmap \s :Startify<CR>
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

function! GetUniqueSessionName()
  let path = fnamemodify(getcwd(), ':~:t')
  let path = empty(path) ? 'no-project' : path
  let branch = gitbranch#name()
  let branch = empty(branch) ? '' : '@' . branch
  return substitute(path . branch, '/', '-', 'g')
endfunction

autocmd User        StartifyReady if getcwd() !~ '/Workspace$' | silent execute 'SLoad '  . GetUniqueSessionName() | endif
autocmd VimLeavePre *             if getcwd() !~ '/Workspace$' | silent execute 'SSave! ' . GetUniqueSessionName() | endif

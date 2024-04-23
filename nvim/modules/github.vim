function! OpenCommitInGitHub()
  let commit_hash = expand('<cword>')
  let repo_url = substitute(system('gh browse -n'), '\n\+$', '', '')
  let commit_url = repo_url . '/commit/' . commit_hash

  call system('start' . ' ' . commit_url)
endfunction

nmap <leader>cc :call OpenCommitInGitHub()<cr>


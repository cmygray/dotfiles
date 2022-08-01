function! OpenCommitInGitHub()
  let commit_hash = expand('<cword>')
  let repo_url = substitute(system('gh browse -n'), '\n\+$', '', '')
  let commit_url = repo_url . '/commit/' . commit_hash

  call netrw#BrowseX(commit_url, netrw#CheckIfRemote())
endfunction

nmap <leader>cc :call OpenCommitInGitHub()<cr>


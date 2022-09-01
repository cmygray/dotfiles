" vim script (work in progress)

function! EditMatchingTestFile()
  let path = expand('%:p:h')
  let pattern = '**/' . expand('%:t:r') . '.spec.ts'
  let file_path = globpath(path, pattern)
  execute 'e ' . file_path
endfunction

function! TestScript()
  :call EditMatchingTestFile()
endfunction

command T :call TestScript()

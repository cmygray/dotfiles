nnoremap <nowait> <C-f> <cmd>lua require('telescope.builtin').find_files({ hidden = true })<cr>
nnoremap <nowait> <C-g> <cmd>lua require('telescope').extensions.live_grep_args.live_grep_args({ hidden = true })<cr>


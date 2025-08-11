lua << EOF
require('kulala').setup({
  global_keymaps = false,
  global_keymaps_prefix = "<leader>R",
  kulala_keymaps_prefix = "",
})
EOF

" Kulala keymaps
nnoremap <silent> <leader>Rs :lua require('kulala').run()<CR>
nnoremap <silent> <leader>Ra :lua require('kulala').run_all()<CR>
nnoremap <silent> <leader>Rb :lua require('kulala').scratchpad()<CR>

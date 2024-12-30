lua << EOF
local telescope = require('telescope')
local telescopeConfig = require('telescope.config')
local lga_actions = require('telescope-live-grep-args.actions')

local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments)}

table.insert(vimgrep_arguments, '--hidden')
table.insert(vimgrep_arguments, '--glob')
table.insert(vimgrep_arguments, '!.git/*')

require('telescope').setup({
  defaults = {
    vimgrep_arguments = vimgrep_arguments,
    file_ignore_patterns = {
      "node_modules/",
    }
  },
  extensions = {
    live_grep_args = {
      auto_quoting = true,
      mappings = {
        i = {
          ['<C-k>'] = lga_actions.quote_prompt(),
        },
      },
    },
  },
  pickers = {
    find_files = {
      find_command = { 'rg', '--files', '--hidden', '--glob', '!.git/*' },
    },
  },
})
EOF

nnoremap <nowait> <C-f> <cmd>lua require('telescope.builtin').find_files()<cr>
nnoremap <nowait> <C-s> <cmd>lua require('telescope.builtin').find_files({ no_ignore = true })<cr>
nnoremap <nowait> <C-g> <cmd>lua require('telescope').extensions.live_grep_args.live_grep_args()<cr>
nnoremap <nowait> <C-b> <cmd>lua require('telescope.builtin').buffers()<cr>


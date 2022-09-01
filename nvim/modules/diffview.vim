lua << EOF
require('diffview').setup({
  file_panel = {
    listing_style = 'list',
    win_config = {
      position = 'top',
      height = 20,
    }
  }
})
EOF

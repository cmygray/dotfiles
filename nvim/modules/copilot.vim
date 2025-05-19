lua << EOF
require("copilot").setup({
  copilot_node_command = os.getenv('HOME') .. "/.local/share/mise/installs/node/20.19.0/bin/node",
  suggestion = {
    auto_trigger = true,  
  }
})
EOF

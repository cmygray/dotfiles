lua << EOF
require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    -- Conform will run multiple formatters sequentially
    python = { "isort", "black" },
    -- You can customize some of the format options for the filetype (:help conform.format)
    rust = { "rustfmt", lsp_format = "fallback" },
    -- Conform will run the first available formatter
    javascript = { "prettierd", "prettier", stop_after_first = true },
    typescript = { "prettierd", "prettier", stop_after_first = true },
    typescriptreact = { "prettierd", "prettier", stop_after_first = true },
    handlebars = { "djlint", "prettierd", "prettier", stop_after_first = true },
    html = { "djlint", "prettierd", "prettier", stop_after_first = true },
    xml = { "xmllint", "prettierd", "prettier", stop_after_first = true },
  },

  format_on_save = {
    timeout_ms = 500,
    lsp_format = "fallback"
  }
})
EOF

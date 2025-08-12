return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    config = function()
      local mason_lspconfig = require("mason-lspconfig")
      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      
      -- LSP 공통 on_attach 함수
      local on_attach = function(client, bufnr)
        local bufopts = { noremap = true, silent = true, buffer = bufnr }
        
        -- LSP 키맵 설정
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
        vim.keymap.set("n", "gu", vim.lsp.buf.references, bufopts)
        vim.keymap.set("n", "gr", vim.lsp.buf.hover, bufopts)
        vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, bufopts)
        vim.keymap.set("n", "<A-Cr>", vim.lsp.buf.code_action, bufopts)
        vim.keymap.set("v", "<A-Cr>", vim.lsp.buf.code_action, bufopts)
        
        -- 진단 관련 키맵
        vim.keymap.set("n", "<leader>j", vim.diagnostic.goto_next, bufopts)
        vim.keymap.set("n", "<leader>k", vim.diagnostic.goto_prev, bufopts)
        vim.keymap.set("n", "<leader>J", function()
          vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
        end, bufopts)
        vim.keymap.set("n", "<leader>K", function()
          vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
        end, bufopts)
      end

      mason_lspconfig.setup({
        ensure_installed = {
          "lua_ls",
          "ts_ls", 
          "yamlls",
          "pyright",
          "html",
          "bashls",
        },
        -- Just ensure servers are installed, configure them separately
        automatic_installation = true,
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      require("lsp")
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local cmp_select = { behavior = cmp.SelectBehavior.Select }
      
      cmp.setup({
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
        mapping = {
          ["<Tab>"] = cmp.mapping.select_next_item(cmp_select),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(cmp_select),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        },
      })
    end,
  },
  {
    "hrsh7th/cmp-nvim-lsp",
  },
  {
    "hrsh7th/cmp-buffer",
  },
  {
    "hrsh7th/cmp-path",
  },
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    build = "make install_jsregexp",
  },
  {
    "saadparwaiz1/cmp_luasnip",
  },
  {
    "stevearc/conform.nvim",
    config = function()
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
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require('nvim-treesitter.configs').setup {
        ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline" },
        sync_install = false,
        auto_install = true,
        ignore_install = { "javascript" },
        highlight = {
          enable = true,
          disable = function(lang, buf)
            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
              return true
            end
          end,
          additional_vim_regex_highlighting = false,
        },
      }
    end,
  },
}
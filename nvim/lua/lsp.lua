-- modules/lsp.lua

-- nvim-cmp (자동완성) 설정
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

-- nvim-lspconfig (LSP) 설정
local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- LSP 공통 설정 (키매핑 등)
local on_attach = function(client, bufnr)
	local bufopts = { noremap = true, silent = true, buffer = bufnr }

	-- 기존 coc.vim 키맵 매핑
	vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
	vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
	vim.keymap.set("n", "gu", vim.lsp.buf.references, bufopts)
	vim.keymap.set("n", "gr", vim.lsp.buf.hover, bufopts)
	vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, bufopts)
	vim.keymap.set("n", "<A-Cr>", vim.lsp.buf.code_action, bufopts)
	vim.keymap.set("v", "<A-Cr>", vim.lsp.buf.code_action, bufopts)

	-- 진단 관련 키맵
	vim.keymap.set("n", "<leader>j", function()
		vim.diagnostic.goto_next()
	end, bufopts)
	vim.keymap.set("n", "<leader>k", function()
		vim.diagnostic.goto_prev()
	end, bufopts)
	vim.keymap.set("n", "<leader>J", function()
		vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
	end, bufopts)
	vim.keymap.set("n", "<leader>K", function()
		vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
	end, bufopts)
end

-- 설치된 LSP 서버 목록 (coc-extensions 기반)
-- 'coc-sh'는 'bashls', 'coc-python'은 'pyright' 또는 'jedi_language_server' 등으로 대체 가능
local servers = { "ts_ls", "yamlls", "lua_ls", "pyright", "html", "bashls" }

-- 각 서버에 대해 설정 적용
for _, lsp in ipairs(servers) do
	lspconfig[lsp].setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

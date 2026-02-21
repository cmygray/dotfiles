return {
	{
		"jparise/vim-graphql",
	},
	{
		"rust-lang/rust.vim",
	},
	{
		"eliba2/vim-node-inspect",
	},
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		build = "cd app; npx --yes yarn install",
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
		end,
		ft = { "markdown" },
	},
	{
		"vimwiki/vimwiki",
		config = function()
			vim.cmd("source " .. vim.fn.stdpath("config") .. "/modules/wiki.vim")
		end,
	},
	{
		"MeanderingProgrammer/render-markdown.nvim",
		config = function()
			vim.cmd("source " .. vim.fn.stdpath("config") .. "/modules/render-markdown.vim")
		end,
	},
}

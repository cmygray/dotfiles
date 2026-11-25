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

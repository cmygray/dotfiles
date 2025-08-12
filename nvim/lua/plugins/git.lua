return {
	{
		"tpope/vim-fugitive",
	},
	{
		"airblade/vim-gitgutter",
	},
	{
		"sindrets/diffview.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			vim.cmd("source " .. vim.fn.stdpath("config") .. "/modules/diffview.vim")
		end,
	},
	{
		"akinsho/git-conflict.nvim",
		version = "*",
		config = function()
			vim.cmd("source " .. vim.fn.stdpath("config") .. "/modules/git-conflict.vim")
		end,
	},
	{
		"rhysd/conflict-marker.vim",
	},
}


return {
	{
		"arcticicestudio/nord-vim",
		priority = 1000,
		config = function()
			-- nord-vim은 `hi clear` 뒤에야 background=dark를 켭니다. 그 순간 background가
			-- light면(터미널 배경 감지 등) nord가 정의하지 않는 @variable 계열이 nvim 기본
			-- light 팔레트(NvimDarkGrey2)로 남아 파라미터·지역 변수가 검게 보입니다.
			vim.api.nvim_create_autocmd("ColorScheme", {
				pattern = "nord",
				callback = function()
					vim.api.nvim_set_hl(0, "@variable", { link = "Identifier" })
					vim.api.nvim_set_hl(0, "@variable.parameter", { link = "Identifier" })
				end,
			})
			vim.o.background = "dark"
			vim.cmd("colorscheme nord")
		end,
	},
	{
		"kyazdani42/nvim-web-devicons",
		opts = {},
	},
	{
		"itchyny/lightline.vim",
		config = function()
			vim.opt.laststatus = 2
			vim.opt.showmode = false

			vim.g.lightline = {
				colorscheme = "nord",
			}
		end,
	},
}


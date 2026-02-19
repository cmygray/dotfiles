return {
	{
		"coder/claudecode.nvim",
		dependencies = {
			{
				"folke/snacks.nvim",
				keys = {
					{ "<C-w>h", "<cmd>wincmd h<cr>", mode = "t" },
					{ "<C-w>l", "<cmd>wincmd l<cr>", mode = "t" },
					{ "<C-w>j", "<cmd>wincmd j<cr>", mode = "t" },
					{ "<C-w>k", "<cmd>wincmd k<cr>", mode = "t" },
				},
			},
		},
		opts = {
			focus_after_send = false,
			track_selection = true,
			terminal = {
				split_width_percentage = 0.50,
				provider = "snacks",
			},
		},
		keys = {
			{ "<leader>a", nil, desc = "AI/Claude Code" },
			{ "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
			{ "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
			{ "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
			{ "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
			{ "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
			{ "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
			{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
			{
				"<leader>as",
				"<cmd>ClaudeCodeTreeAdd<cr>",
				desc = "Add file",
				ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
			},
			-- Diff management
			{ "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
			{ "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
		},
	},
	{
		"tpope/vim-surround",
	},
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-live-grep-args.nvim",
		},
		config = function()
			local telescope = require("telescope")
			local telescopeConfig = require("telescope.config")
			local lga_actions = require("telescope-live-grep-args.actions")

			local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments) }

			table.insert(vimgrep_arguments, "--hidden")
			table.insert(vimgrep_arguments, "--glob")
			table.insert(vimgrep_arguments, "!.git/*")

			telescope.setup({
				defaults = {
					vimgrep_arguments = vimgrep_arguments,
					file_ignore_patterns = {
						"node_modules/",
					},
				},
				extensions = {
					live_grep_args = {
						auto_quoting = true,
						mappings = {
							i = {
								["<C-k>"] = lga_actions.quote_prompt(),
							},
						},
					},
				},
				pickers = {
					find_files = {
						find_command = { "rg", "--files", "--hidden", "--glob", "!.git/*" },
					},
				},
			})

			-- Keymaps
			vim.keymap.set("n", "<C-f>", "<cmd>lua require('telescope.builtin').find_files()<cr>", { nowait = true })
			vim.keymap.set(
				"n",
				"<C-s>",
				"<cmd>lua require('telescope.builtin').find_files({ no_ignore = true })<cr>",
				{ nowait = true }
			)
			vim.keymap.set(
				"n",
				"<C-g>",
				"<cmd>lua require('telescope').extensions.live_grep_args.live_grep_args()<cr>",
				{ nowait = true }
			)
			vim.keymap.set("n", "<C-b>", "<cmd>lua require('telescope.builtin').buffers()<cr>", { nowait = true })
		end,
	},
	{
		"nvim-telescope/telescope-live-grep-args.nvim",
		dependencies = { "nvim-telescope/telescope.nvim" },
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = function()
			require("nvim-autopairs").setup({})
		end,
	},
	{
		"chaoren/vim-wordmotion",
		init = function()
			vim.g.wordmotion_prefix = "["
		end,
	},
	{
		"stevearc/oil.nvim",
		dependencies = { "kyazdani42/nvim-web-devicons" },
		config = function()
			-- Declare a global function to retrieve the current directory
			function _G.get_oil_winbar()
				local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
				local dir = require("oil").get_current_dir(bufnr)
				if dir then
					return vim.fn.fnamemodify(dir, ":~")
				else
					-- If there is no current directory (e.g. over ssh), just show the buffer name
					return vim.api.nvim_buf_get_name(0)
				end
			end

			require("oil").setup({
				default_file_explorer = true,
				delete_to_trash = true,
				skip_confirm_for_simple_edits = true,
				win_options = {
					winbar = "%!v:lua.get_oil_winbar()",
				},
				view_options = {
					show_hidden = true,
					natural_order = true,
					is_always_hidden = function(name, _)
						return name == ".." or name == ".git"
					end,
				},
				preview_win = {
					preview_method = "load",
				},
			})

			vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
			vim.keymap.set("n", "<Leader>-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
		end,
	},
	{
		"lalitmee/browse.nvim",
		dependencies = { "nvim-telescope/telescope.nvim" },
	},
	{
		"nanotee/zoxide.vim",
	},
	{
		"kevinhwang91/nvim-ufo",
		dependencies = { "kevinhwang91/promise-async" },
		config = function()
			vim.o.foldcolumn = "1"
			vim.o.foldlevel = 99
			vim.o.foldlevelstart = 99
			vim.o.foldenable = true

			require("ufo").setup()
		end,
	},
	{
		"kevinhwang91/nvim-bqf",
	},
	{
		"kevinhwang91/promise-async",
	},
	{
		"chrisbra/csv.vim",
	},
	{
		"3rd/image.nvim",
		build = false,
		opts = {
			processor = "magick_cli",
			backend = "kitty",
			max_width_window_percentage = 100,
			max_height_window_percentage = 100,
		},
	},
	{
		"simnalamburt/vim-tiny-ime",
	},
	{
		"stevearc/dressing.nvim",
	},
	{
		"MunifTanjim/nui.nvim",
	},
	{
		"junegunn/fzf",
	},
	{
		"mhinz/vim-startify",
		dependencies = { "itchyny/vim-gitbranch" },
		config = function()
			-- GetAutoSessionName function
			vim.cmd([[
        function! GetAutoSessionName()
          let path = substitute(getcwd(), $HOME, '', '')
          let path = substitute(path, '^/', '', '')
          let branch = gitbranch#name()
          let branch = empty(branch) ? '' : '@' . branch
          return substitute(path . branch, '/', '-', 'g')
        endfunction
      ]])

			-- Key mappings
			vim.keymap.set("n", "\\s", ':execute "SSave! " . GetAutoSessionName()<CR>')
			vim.keymap.set("n", "\\S", ":Startify<CR>")
			vim.keymap.set("n", "\\d", ":SDelete<CR>y<CR>")

			-- Startify configuration
			vim.g.startify_list_order = {
				{ "    Sessions" },
				"sessions",
				{ "    Most Recently Used files" },
				"files",
				"bookmarks",
				{ "    Commands" },
				"commands",
			}

			-- Autocommands
			vim.api.nvim_create_augroup("vimstartify", { clear = true })
			vim.api.nvim_create_autocmd("User", {
				group = "vimstartify",
				pattern = "Startified",
				callback = function()
					vim.opt.cursorline = true
				end,
			})
		end,
	},
}
